// native/src/api.rs
//
// This file serves as the clean gateway for Flutter-Rust Bridge (FRB)
//
// All hardware interaction is delegated to the driver layer.

use crate::drivers::ble_driver::{
    connect_to_device, execute_on_hardware, read_gpio_u32, update_gpio_bit,
    update_gpio_mask, read_gpio_register, reset_cpu, shutdown_board,
};
use crate::registers::*;

// Public Data Structures

#[derive(Clone)]
pub struct TelemetryData {
    pub name: String,
    pub power_on: bool,
    pub frequency: f32,
    pub voltage: f32,
    pub temperature: f32,
    pub humidity: f32,
    pub power: f32,
    pub pressure: f32,
}

#[derive(Default, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct UsbStatus {
    pub usb0_pow_sw: bool,
    pub usb0_reset: bool,
    pub usb0_hs_led: bool,
    pub usb0_detect_led: bool,
    pub usb1_pow_sw: bool,
    pub usb1_reset: bool,
    pub usb1_hs_led: bool,
    pub usb1_detect_led: bool,
    pub usbc_esd_status: bool,
}

#[derive(Default, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct PcieStatus {
    pub pcie_status: bool,
    pub pcie_outputs: u32,
    pub pcie_ss_sel_tri: bool,
    pub pcie_buffer_state: u32,
}

pub struct IntrAlertStatus {
    pub asics_eth_int: bool,
    pub alert_sig_asics_monitor: bool,
    pub adc_int: bool,
    pub motherboard_eth_int: bool,
}

pub struct PwrClkStatus {
    pub pmic_control: bool,
    pub sata_connector_power: u32,
    pub serdes_clk_en: bool,
    pub i2c_mux_reset: bool,
    pub ftdi_reset: bool,
}

pub struct InterfaceMuxStatus {
    pub brom_sd_en: bool,
    pub brom_sd_sel: bool,
    pub uart_asic_ftdi_mux: u32,
    pub jtag_asic_ftdi_mux: u32,
    pub sata_e_redriver_en: bool,
    pub displayport_redriver: bool,
    pub pmod_spi: u32,
    pub i2s_audio_dac_gain: u32,
}

// Public API: Status Reads

/// Reads the USB register and returns structured status
pub fn read_usb_status() -> Result<UsbStatus, String> {
    let v = read_gpio_u32(USB_REG)?;
    Ok(UsbStatus {
        usb0_pow_sw: (v & USB0_POWSW_BIT) != 0,
        usb0_reset: (v & USB0_RESET_BIT) != 0,
        usb0_hs_led: (v & USB0_HS_LED_BIT) != 0,
        usb0_detect_led: (v & USB0_DETECT_LED_BIT) != 0,
        usb1_pow_sw: (v & USB1_POWSW_BIT) != 0,
        usb1_reset: (v & USB1_RESET_BIT) != 0,
        usb1_hs_led: (v & USB1_HS_LED_BIT) != 0,
        usb1_detect_led: (v & USB1_DETECT_LED_BIT) != 0,
        usbc_esd_status: (v & USB_C_ESD_STATUS_BIT) != 0,
    })
}

/// Reads the PCIe register and returns structured status
pub fn read_pcie_status() -> Result<PcieStatus, String> {
    let v = read_gpio_u32(PCIE_REG)?;
    Ok(PcieStatus {
        pcie_status: (v & PCIE_STATUS_BIT) != 0,
        pcie_outputs: (v & PCIE_OUTPUTS_MASK) >> 1,
        pcie_ss_sel_tri: (v & PCIE_SS_SEL_TRI_BIT) != 0,
        pcie_buffer_state: (v & PCIE_BUFFER_STATE_MASK) >> 6,
    })
}

/// Reads the interrupt/alert register and returns structured status
pub fn read_intr_alert_status() -> Result<IntrAlertStatus, String> {
    let v = read_gpio_u32(INTR_ALERT_REG)?;
    Ok(IntrAlertStatus {
        asics_eth_int: (v & ASIC_ETH_INT_BIT) != 0,
        alert_sig_asics_monitor: (v & ALERT_SIG_ASIC_MONITOR_BIT) != 0,
        adc_int: (v & ADC_INT_BIT) != 0,
        motherboard_eth_int: (v & MOTHERBOARD_ETH_INT_BIT) != 0,
    })
}

/// Reads the power/clock register and returns structured status
pub fn read_pwr_clk_status() -> Result<PwrClkStatus, String> {
    let v = read_gpio_u32(PWR_CLK_REG)?;
    Ok(PwrClkStatus {
        pmic_control: (v & PMIC_CONTROL_BIT) != 0,
        sata_connector_power: (v & SATA_POWER_MASK) >> 1,
        serdes_clk_en: (v & SERDES_CLK_EN_BIT) != 0,
        i2c_mux_reset: (v & I2C_MUX_RESET_BIT) != 0,
        ftdi_reset: (v & FTDI_RESET_BIT) != 0,
    })
}

/// Reads the interface mux register and returns structured status
pub fn read_interface_mux_status() -> Result<InterfaceMuxStatus, String> {
    let v = read_gpio_u32(INTERFACE_MUX_REG)?;
    Ok(InterfaceMuxStatus {
        brom_sd_en: (v & BROM_SD_EN_BIT) != 0,
        brom_sd_sel: (v & BROM_SD_SEL_BIT) != 0,
        uart_asic_ftdi_mux: (v & UART_ASIC_FTDI_MUX_MASK) >> 2,
        jtag_asic_ftdi_mux: (v & JTAG_ASIC_FTDI_MUX_MASK) >> 4,
        sata_e_redriver_en: (v & SATA_E_REDRIVER_EN_BIT) != 0,
        displayport_redriver: (v & DISPLAYPORT_REDRIVER_BIT) != 0,
        pmod_spi: (v & PMOD_SPI_MASK) >> 16,
        i2s_audio_dac_gain: (v & I2S_AUDIO_DAC_GAIN_MASK) >> 23,
    })
}

// Public API: Control Functions

pub fn connect_to_board(target_mac: String) -> Result<(), String> {
    connect_to_device(&target_mac)
}

pub fn set_simulation_mode(on: bool) {
    println!("set_simulation_mode({}) called: simulation handled in Flutter.", on);
}

pub fn toggle_power() -> bool {
    execute_on_hardware(|_| Ok(())).is_ok()
}

pub fn toggle_usb0_power(enable: bool) -> Result<(), String> {
    update_gpio_bit(USB_REG, USB0_POWSW_BIT, enable)
}

pub fn toggle_usb0_reset(enable: bool) -> Result<(), String> {
    update_gpio_bit(USB_REG, USB0_RESET_BIT, enable)
}

pub fn toggle_usb1_power(enable: bool) -> Result<(), String> {
    update_gpio_bit(USB_REG, USB1_POWSW_BIT, enable)
}

pub fn toggle_usb1_reset(enable: bool) -> Result<(), String> {
    update_gpio_bit(USB_REG, USB1_RESET_BIT, enable)
}

pub fn set_sata_power(level: u32) -> Result<(), String> {
    update_gpio_mask(PWR_CLK_REG, SATA_POWER_MASK, 1, level)
}

pub fn set_pcie_outputs(level: u32) -> Result<(), String> {
    update_gpio_mask(PCIE_REG, PCIE_OUTPUTS_MASK, 1, level)
}

pub fn toggle_serdes_clock(enable: bool) -> Result<(), String> {
    update_gpio_bit(PWR_CLK_REG, SERDES_CLK_EN_BIT, enable)
}

pub fn toggle_i2c_mux_reset(enable: bool) -> Result<(), String> {
    update_gpio_bit(PWR_CLK_REG, I2C_MUX_RESET_BIT, enable)
}

pub fn toggle_ftdi_reset(enable: bool) -> Result<(), String> {
    update_gpio_bit(PWR_CLK_REG, FTDI_RESET_BIT, enable)
}

pub fn reset_cpu_api() -> Result<(), String> {
    reset_cpu()
}

pub fn shutdown_board_api() -> Result<(), String> {
    shutdown_board()
}

pub fn write_gpio_register_api(addr: u8, data_payload: [u8; 4]) -> Result<(), String> {
    crate::drivers::ble_driver::write_gpio_register(addr, data_payload)
}

pub fn read_gpio_register_api(addr: u8) -> Result<[u8; 4], String> {
    read_gpio_register(addr)
}

// Public API: Telemetry

/// Reads a 32-bit float from a telemetry register
fn read_f32_register(addr: u8) -> Result<f32, String> {
    let payload = read_gpio_register(addr)?;
    Ok(f32::from_le_bytes(payload))
}

/// Retrieves current board telemetry (frequency, voltage, temperature, etc.)
pub fn get_telemetry() -> TelemetryData {
    let telemetry = (|| -> Result<TelemetryData, String> {
        let frequency = read_f32_register(TELEMETRY_FREQ_REG)?;
        let voltage = read_f32_register(TELEMETRY_VOLTAGE_REG)?;
        let temperature = read_f32_register(TELEMETRY_TEMPERATURE_REG)?;
        let humidity = read_f32_register(TELEMETRY_HUMIDITY_REG)?;
        let power = read_f32_register(TELEMETRY_POWER_REG)?;
        let pressure = read_f32_register(TELEMETRY_PRESSURE_REG)?;

        Ok(TelemetryData {
            name: "Mondragon 1.1".to_string(),
            power_on: frequency != 0.0,
            frequency,
            voltage,
            temperature,
            humidity,
            power,
            pressure,
        })
    })();

    match telemetry {
        Ok(data) => data,
        Err(_) => {
            TelemetryData {
                name: "Mondragon 1.1".to_string(),
                power_on: false,
                frequency: 0.0,
                voltage: 0.0,
                temperature: 0.0,
                humidity: 0.0,
                power: 0.0,
                pressure: 0.0,
            }
        }
    }
}

