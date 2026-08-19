use crate::protocol::mondragon_protocol::Command;
use std::io::Error;

pub trait Comms {
	type Error: From<Error>;
	fn send(&self, buf: &[u8]) -> Result<usize, Self::Error>;
	fn receive(&self, buf: &mut [u8]) -> Result<usize, Self::Error>;
}

// MASTER FUNCTIONS (used by Dratel App to send commands)

/// Read Register Command
/// TX: [0x03, seq_num, addr]
/// RX: [0x00, seq_num, data0, data1, data2, data3] OR [0x01, seq_num, error_code]
pub fn send_read_register<T: Comms>(
	ins: &T,
	seq_num: u8,
	addr: u8,
) -> Result<u32, T::Error> {
	let mut tx_buffer = [0u8; 3];

	tx_buffer[0] = Command::ReadReg.into();
	tx_buffer[1] = seq_num;
	tx_buffer[2] = addr;

	ins.send(&tx_buffer)?;

	// RX Response: ACK [0x00, seq] + [data0, data1, data2, data3]
	// or: NAK [0x01, seq, error_code]
	let mut rx_buffer = [0u8; 6];

	ins.receive(&mut rx_buffer)?;

	// Validate response
	match rx_buffer[0] {
		0x00 => {
			// ACK: 4 byte payload
			let mut payload = [0u8; 4];
			payload.copy_from_slice(&rx_buffer[2..6]);
			Ok(u32::from_le_bytes(payload))
		},
		0x01 => {
			// NAK: Error response
			let error_code = rx_buffer[2];
			let error_name = match error_code {
				0x01 => "InvalidCommand",
				0x02 => "InvalidAddress",
				0x03 => "WriteProtected",
				0x04 => "SequenceMismatch",
				0x05 => "HardwareFault",
				0x06 => "DeviceBusy",
				0x07 => "PayloadCorrupted",
				0x08 => "ValueOutOfRange",
				0x09 => "HardwareTimeOut",
				0x0A => "InvalidFloat",
				_ => "UnknownError",
			};
			Err(Error::new(
				std::io::ErrorKind::Other,
				format!("Hardware NAK: {} (code: 0x{:02X})", error_name, error_code),
			).into())
		},
		_ => {
			Err(Error::new(
				std::io::ErrorKind::InvalidData,
				format!("Unexpected response command: 0x{:02X}", rx_buffer[0]),
			).into())
		},
	}
}

/// Write Register Command
/// TX: [0x04, seq_num, addr, data0, data1, data2, data3]
/// RX: [0x00, seq_num] OR [0x01, seq_num, error_code]
pub fn send_write_register<T: Comms>(
	ins: &T,
	seq_num: u8,
	addr: u8,
	data_payload: u32,
) -> Result<(), T::Error> {

	let mut tx_buffer = [0u8; 7];

	tx_buffer[0] = Command::WriteReg.into();
	tx_buffer[1] = seq_num;
	tx_buffer[2] = addr;

    tx_buffer[3..7].copy_from_slice(&data_payload.to_le_bytes());

	ins.send(&tx_buffer)?;
	
	// RX Acknowledge [cmd, seq]
	let mut rx_buffer = [0u8; 2]; //[cmd, seq]
	ins.receive(&mut rx_buffer)?;
	
	Ok(())
}

/// Reset CPU Command
/// TX: [0x98, seq_num]
/// RX: [0x00, seq_num] OR [0x01, seq_num, error_code]
pub fn send_reset_cpu<T: Comms>(ins: &T, seq_num: u8) -> Result<(), T::Error> {
	let tx_buffer = [Command::ResetCPU.into(), seq_num];
	ins.send(&tx_buffer)?;

	let mut rx_buffer = [0u8; 3];
	ins.receive(&mut rx_buffer)?;
	
	match rx_buffer[0] {
		0x00 => Ok(()),
		0x01 => Err(Error::new(
			std::io::ErrorKind::Other,
			format!("Reset CPU NAK: error code 0x{:02X}", rx_buffer[2]),
		).into()),
		_ => Err(Error::new(
			std::io::ErrorKind::InvalidData,
			format!("Unexpected response: 0x{:02X}", rx_buffer[0]),
		).into()),
	}
}

/// Shutdown Command
/// TX: [0x99, seq_num]
/// RX: [0x00, seq_num] OR [0x01, seq_num, error_code]
pub fn send_shutdown<T: Comms>(ins: &T, seq_num: u8) -> Result<(), T::Error> {
	let tx_buffer = [Command::ShutDown.into(), seq_num];
	ins.send(&tx_buffer)?;

	let mut rx_buffer = [0u8; 3];
	ins.receive(&mut rx_buffer)?;
	
	match rx_buffer[0] {
		0x00 => Ok(()),
		0x01 => Err(Error::new(
			std::io::ErrorKind::Other,
			format!("Shutdown NAK: error code 0x{:02X}", rx_buffer[2]),
		).into()),
		_ => Err(Error::new(
			std::io::ErrorKind::InvalidData,
			format!("Unexpected response: 0x{:02X}", rx_buffer[0]),
		).into()),
	}
}
