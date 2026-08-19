// Mock para probar la app sin la placa
use std::io::Error;
use crate::protocol::coms::Comms;

pub struct MockComms;

impl Comms for MockComms {
    type Error = Error;

    fn send(&self, buf: &[u8]) -> Result<usize, Self::Error> {
        println!("SIMULATOR: Sending bytes to board -> {:?}", buf);
        Ok(buf.len())
    }

    fn receive(&self, buf: &mut [u8]) -> Result<usize, Self::Error> {
        buf[0] = 0x00; // cmd::Ack
        buf[1] = 1;    // fake sequence number
        
        if buf.len() == 6 {
            buf[2..6].copy_from_slice(&[0x00, 0x00, 0x00, 0x1A]); // fake payload
        }
        
        Ok(buf.len())
    }
}