//! This module defines the mondragon protocol

/// All the commands for the mondragon protocol
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum Command {
	/// Acknowledges the successful receipt of a packet, also works for error and data reponses
	Ack,
	/// Negative Acknowledgement, indicates an error in the received packet
	Nak,
	/// Reads data from a specific register
	ReadReg,
	/// Writes data to a specific register
	WriteReg,
	/// Performs a system reset
	ResetCPU,
	/// Powers down the system
	ShutDown,
}

impl From<Command> for u8 {
	fn from(value: Command) -> Self {
		match value {
			Command::Ack => 0x00,
			Command::Nak => 0x01,
			Command::ReadReg => 0x03,
			Command::WriteReg => 0x04,
			Command::ResetCPU => 0x98,
			Command::ShutDown => 0x99,
		}
	}
}

impl TryFrom<u8> for Command {
	type Error = ();

	fn try_from(value: u8) -> core::result::Result<Self, ()> {
		match value {
			0x00 => Ok(Self::Ack),
			0x01 => Ok(Self::Nak),
			0x03 => Ok(Self::ReadReg),
			0x04 => Ok(Self::WriteReg),
			0x98 => Ok(Self::ResetCPU),
			0x99 => Ok(Self::ShutDown),
			_ => Err(()),
		}
	}
}
