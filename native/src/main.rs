use std::io::{Read, Write};
use std::time::Duration;

fn main() {
    let port_name = "/dev/ttyUSB2"; 
    let baud_rate = 115200;

    println!("Starting hardware test on {} at {} baud...", port_name, baud_rate);
    interact_with_board(port_name, baud_rate);
}

pub fn interact_with_board(port_name: &str, baud_rate: u32) {
    let port_result = serialport::new(port_name, baud_rate)
        .timeout(Duration::from_millis(1000))
        .open();

    match port_result {
        Ok(mut port) => {
            println!("Success: Connected to {}", port_name);

            // WRITE DATA
            let command = "STATUS\n"; 
            match port.write(command.as_bytes()) {
                Ok(_) => println!("Command successfully sent to board."),
                Err(e) => println!("Failed to write command: {}", e),
            }

            // READ DATA
            let mut serial_buf: Vec<u8> = vec![0; 256];
            match port.read(serial_buf.as_mut_slice()) {
                Ok(bytes_read) => {
                    let received_data = String::from_utf8_lossy(&serial_buf[..bytes_read]);
                    println!("Raw data received:\n{}", received_data);
                }
                Err(e) => println!("Failed to read data: {}", e),
            }
        }
        Err(e) => {
            println!("Error: Could not open port {}. Details: {}", port_name, e);
        }
    }
}