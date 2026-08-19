use once_cell::sync::Lazy;
use std::sync::Mutex;
use std::time::Duration;

use btleplug::api::{Central, Manager as _, Peripheral as ApiPeripheralTrait, ScanFilter};
use btleplug::platform::{Manager, Peripheral};
use std::io::{Error, ErrorKind};
use btleplug::api::{Characteristic, WriteType};
use uuid::Uuid;

use crate::protocol::coms::{send_read_register, send_shutdown, send_reset_cpu, send_write_register};

// Bluetooth Driver Constants
const SCAN_TIMEOUT_SECS: u64 = 2;

// UUIDs for Bluetooth communication
const TX_CHARACTERISTIC_UUID: Uuid = Uuid::from_u128(0x5f652761f56d40039f94b0a13151e03b);
const RX_CHARACTERISTIC_UUID: Uuid = Uuid::from_u128(0x5f652762f56d40039f94b0a13151e03b);

/// Lazy-initialized state holding the active Bluetooth driver connection
static HW_STATE: Lazy<Mutex<Option<BluetoothDriver>>> = Lazy::new(|| Mutex::new(None));

/// Bluetooth driver for communicating with Mondragon
pub struct BluetoothDriver {
    pub device: Peripheral,
    pub tx_characteristic: Characteristic,
    pub rx_characteristic: Characteristic,
}

impl crate::protocol::coms::Comms for BluetoothDriver {
    type Error = Error;

    /// Sends bytes to Mondragon
    fn send(&self, buf: &[u8]) -> Result<usize, Self::Error> {
        futures::executor::block_on(
            self.device.write(&self.tx_characteristic, buf, WriteType::WithoutResponse)
        ).map_err(|e| Error::new(ErrorKind::NotConnected, e.to_string()))?;
        Ok(buf.len())
    }

    /// Receives bytes from Mondragon
    fn receive(&self, buf: &mut [u8]) -> Result<usize, Self::Error> {
        let data_in = futures::executor::block_on(
            self.device.read(&self.rx_characteristic)
        ).map_err(|e| Error::new(ErrorKind::NotConnected, e.to_string()))?;

        let bytes = data_in.len().min(buf.len());
        buf[..bytes].copy_from_slice(&data_in[..bytes]);
        Ok(bytes)
    }
}

impl BluetoothDriver {
    /// Connects to the board and discovers TX/RX characteristics
    pub fn new(device: Peripheral) -> Result<Self, String> {
        futures::executor::block_on(device.connect())
            .map_err(|e| format!("Failed to connect to device: {}", e))?;

        futures::executor::block_on(device.discover_services())
            .map_err(|e| format!("Failed to discover services: {}", e))?;

        let mut tx_characteristic = None;
        let mut rx_characteristic = None;

        for characteristic in device.characteristics() {
            if characteristic.uuid == TX_CHARACTERISTIC_UUID {
                tx_characteristic = Some(characteristic);
            } else if characteristic.uuid == RX_CHARACTERISTIC_UUID {
                rx_characteristic = Some(characteristic);
            }
        }

        let tx_characteristic = tx_characteristic.ok_or("TX characteristic not found")?;
        let rx_characteristic = rx_characteristic.ok_or("RX characteristic not found")?;

        Ok(BluetoothDriver {
            device,
            tx_characteristic,
            rx_characteristic,
        })
    }
}

/// 1. CONNECTION PHASE
/// Public function exposed to Flutter. Called ONCE when connecting to the board.
pub fn connect_to_device(target_mac: &str) -> Result<(), String> {
    let runtime = tokio::runtime::Runtime::new().map_err(|e| e.to_string())?;
    
    runtime.block_on(async {
        // Disconnect previous if any
        clear_stored_driver();

        let driver = scan_and_connect_driver(target_mac).await?;
        
        let mut state = HW_STATE
            .lock()
            .map_err(|e| format!("HW_STATE lock error: {e}"))?;
        *state = Some(driver);
        
        Ok::<(), String>(())
    })?;

    Ok(())
}

/// Internal async function to scan and connect using the provided MAC address
async fn scan_and_connect_driver(target_mac: &str) -> Result<BluetoothDriver, String> {
    let manager = Manager::new()
        .await
        .map_err(|e| format!("Failed to initialize Bluetooth manager: {e}"))?;

    let adapters = manager
        .adapters()
        .await
        .map_err(|e| format!("Failed to enumerate Bluetooth adapters: {e}"))?;

    let adapter = adapters
        .into_iter()
        .next()
        .ok_or_else(|| "No Bluetooth adapters available".to_string())?;

    adapter
        .start_scan(ScanFilter::default())
        .await
        .map_err(|e| format!("Failed to start Bluetooth scan: {e}"))?;

    tokio::time::sleep(Duration::from_secs(SCAN_TIMEOUT_SECS)).await;

    let peripherals = adapter
        .peripherals()
        .await
        .map_err(|e| format!("Failed to get peripherals: {e}"))?;

    let mut candidate: Option<Peripheral> = None;

    for peripheral in &peripherals {
        // Filter strictly by MAC address. Name is not required to match.
        if peripheral.address().to_string().to_uppercase() == target_mac.to_uppercase() {
            candidate = Some(peripheral.clone());
            break;
        }
    }

    let device = candidate.ok_or_else(|| {
        "No board found over Bluetooth. Confirm the board is advertising and in range.".to_string()
    })?;

    BluetoothDriver::new(device).map_err(|e| e.to_string())
}

/// Clears the stored driver state (called after errors or when reconnecting)
fn clear_stored_driver() {
    if let Ok(mut state) = HW_STATE.lock() {
        *state = None;
    }
}

/// 2. EXECUTION PHASE
/// Main hardware orchestration function: relies on the existing connection state.
pub fn execute_on_hardware<R>(operation: impl FnOnce(&BluetoothDriver) -> Result<R, String>) -> Result<R, String> {
    let result = {
        let state = HW_STATE
            .lock()
            .map_err(|e| format!("HW_STATE lock error: {e}"))?;
            
        let driver = state
            .as_ref()
            .ok_or_else(|| "Bluetooth driver not available. Please call connect_to_device() first.".to_string())?;
            
        operation(driver)
    };

    if result.is_err() {
        clear_stored_driver();
    }

    result
}

// GPIO AND HARDWARE COMMANDS

/// Reads a 32-bit GPIO register
pub fn read_gpio_u32(addr: u8) -> Result<u32, String> {
    let payload = read_gpio_register(addr)?;
    Ok(u32::from_le_bytes(payload))
}

/// Writes a 32-bit GPIO register
pub fn write_gpio_u32(addr: u8, value: u32) -> Result<(), String> {
    write_gpio_register(addr, value.to_le_bytes())
}

/// Updates a single bit in a GPIO register
pub fn update_gpio_bit(addr: u8, mask: u32, enable: bool) -> Result<(), String> {
    let mut value = read_gpio_u32(addr)?;
    if enable {
        value |= mask;
    } else {
        value &= !mask;
    }
    write_gpio_u32(addr, value)
}

/// Updates a masked field in a GPIO register
pub fn update_gpio_mask(addr: u8, mask: u32, shift: u8, value: u32) -> Result<(), String> {
    let mut reg = read_gpio_u32(addr)?;
    reg &= !mask;
    let v = (value << shift) & mask;
    reg |= v;
    write_gpio_u32(addr, reg)
}

/// Reads raw bytes from a GPIO register
pub fn read_gpio_register(addr: u8) -> Result<[u8; 4], String> {
    execute_on_hardware(|driver| {
        send_read_register(driver, 1, addr)
            .map(|u32_val| u32_val.to_le_bytes())
            .map_err(|e| e.to_string())
    })
}

/// Writes raw bytes to a GPIO register
pub fn write_gpio_register(addr: u8, data_payload: [u8; 4]) -> Result<(), String> {
    let u32_val = u32::from_le_bytes(data_payload);
    execute_on_hardware(|driver| send_write_register(driver, 1, addr, u32_val).map_err(|e| e.to_string()))
}

/// Sends a reset CPU command to the board
pub fn reset_cpu() -> Result<(), String> {
    execute_on_hardware(|driver| send_reset_cpu(driver, 1).map_err(|e| e.to_string()))
}

/// Sends a shutdown command to the board
pub fn shutdown_board() -> Result<(), String> {
    execute_on_hardware(|driver| send_shutdown(driver, 1).map_err(|e| e.to_string()))
}