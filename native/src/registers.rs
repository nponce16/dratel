// Separation of Concerns: All hardware constants extracted to this dedicated module.

use crate::api::{UsbStatus, PcieStatus, IntrAlertStatus};

pub(crate) trait Register {
    const ADDRESS: u8;
}


impl Register for UsbStatus {
    const ADDRESS: u8 = 0x10;
}

impl Register for PcieStatus {
    const ADDRESS: u8 = 0x11;
}

impl Register for IntrAlertStatus {
    const ADDRESS: u8 = 0x12;
}

// Telemetry Registers
pub const TELEMETRY_FREQ_REG: u8 = 0x50;
pub const TELEMETRY_VOLTAGE_REG: u8 = 0x51;
pub const TELEMETRY_TEMPERATURE_REG: u8 = 0x52;
pub const TELEMETRY_HUMIDITY_REG: u8 = 0x53;
pub const TELEMETRY_POWER_REG: u8 = 0x54;
pub const TELEMETRY_PRESSURE_REG: u8 = 0x55;

// Hardware Registers
pub const USB_REG: u8 = 0x10;
pub const PCIE_REG: u8 = 0x11;
pub const INTR_ALERT_REG: u8 = 0x12;
pub const PWR_CLK_REG: u8 = 0x13;
pub const INTERFACE_MUX_REG: u8 = 0x14;

// USB_REG Bitmasks
pub const USB0_POWSW_BIT: u32 = 1 << 0;
pub const USB0_RESET_BIT: u32 = 1 << 1;
pub const USB0_HS_LED_BIT: u32 = 1 << 2;
pub const USB0_DETECT_LED_BIT: u32 = 1 << 3;
pub const USB1_POWSW_BIT: u32 = 1 << 16;
pub const USB1_RESET_BIT: u32 = 1 << 17;
pub const USB1_HS_LED_BIT: u32 = 1 << 18;
pub const USB1_DETECT_LED_BIT: u32 = 1 << 19;
pub const USB_C_ESD_STATUS_BIT: u32 = 1 << 31;

// PCIE_REG Bitmasks
pub const PCIE_STATUS_BIT: u32 = 1 << 0;
pub const PCIE_OUTPUTS_MASK: u32 = 0xF << 1;
pub const PCIE_SS_SEL_TRI_BIT: u32 = 1 << 5;
pub const PCIE_BUFFER_STATE_MASK: u32 = 0x3 << 6;

// INTR_ALERT_REG Bitmasks
pub const ASIC_ETH_INT_BIT: u32 = 1 << 0;
pub const ALERT_SIG_ASIC_MONITOR_BIT: u32 = 1 << 1;
pub const ADC_INT_BIT: u32 = 1 << 2;
pub const MOTHERBOARD_ETH_INT_BIT: u32 = 1 << 31;

// PWR_CLK_REG Bitmasks
pub const PMIC_CONTROL_BIT: u32 = 1 << 0;
pub const SATA_POWER_MASK: u32 = 0xF << 1;
pub const SERDES_CLK_EN_BIT: u32 = 1 << 5;
pub const I2C_MUX_RESET_BIT: u32 = 1 << 30;
pub const FTDI_RESET_BIT: u32 = 1 << 31;

// INTERFACE_MUX_REG Bitmasks
pub const BROM_SD_EN_BIT: u32 = 1 << 0;
pub const BROM_SD_SEL_BIT: u32 = 1 << 1;
pub const UART_ASIC_FTDI_MUX_MASK: u32 = 0x3 << 2;
pub const JTAG_ASIC_FTDI_MUX_MASK: u32 = 0x3 << 4;
pub const SATA_E_REDRIVER_EN_BIT: u32 = 1 << 8;
pub const DISPLAYPORT_REDRIVER_BIT: u32 = 1 << 9;
pub const PMOD_SPI_MASK: u32 = 0x7 << 16;
pub const I2S_AUDIO_DAC_GAIN_MASK: u32 = 0x7 << 23;
