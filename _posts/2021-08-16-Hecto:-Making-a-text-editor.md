---
layout: post
title: "Hecto: Making a text editor"
categories: hecto
---

**Dependancies (Cargo.toml)**
```toml
[package]
name = "hecto"
version = "0.1.0"
edition = "2018"

[dependencies]
termion = "1"
```

`termion` is used to go into raw mode, raw mode won't let us input characters directly into the screen, enter also doesn't need to be pressed for it to count as input. This is handy because the byte code for each button can be extracted. The only down side for this is that the in order for output to be shown from user input, it must be done manually.

The usual method is to take in user input, then process it but the standard way requires the user to press a character then the enter key, after the enter key is pressed only will the character be processed. Raw mode skips that and the character can be processed immediately.

```rust
use std::io::{self, stdout};

use termion::event::Key;
use termion::input::TermRead;
use termion::raw::IntoRawMode;

fn main() {
    let _stdout = stdout().into_raw_mode().unwrap();

    for key in io::stdin().keys() {
        match key {
            Ok(key) => match key {
                Key::Char(c) => {
                    if c.is_control() {
                        println!("{:?}\r", c as u8);
                    } else {
                        println!("{:?} ({})\r", c as u8, c);
                    }
                },
                Key::Ctrl('q') => break,
                _ => println!("{:?}\r", key),
            },
            Err(e) => panic!(e),
        }
    }
}
```

Every key press is matched and then checks to see if that character is a printable character with `is_control()`. Printable characters are from ASCII codes 32-126, 0-31, and 127 are all control characters. Control characters are things like the backspace key, control key combinations, etc.

If it is a control character then the character will be converted to bytes and printed out. If the key combination pressed is ctrl+q it will end the process.

> Character to byte -> `char as u8`  
> byte to char -> `byte as char`

# Creating the editor module
Everything related to editing will be in that module. First are the imports.
```rust
use std::io::{self, stdout, Write};

use termion::event::Key;
use termion::input::TermRead;
use termion::raw::IntoRawMode;
```
The editor struct
```rust
pub struct Editor {
    should_quit: bool
}
```
Next are the functions
```rust
pub fn read_key() -> Result<Key, std::io::Error> {
    loop {
        if let Some(key) = io::stdin().lock().keys().next() {
            return key;
        }
    }
}

impl Editor {
    pub fn new() -> Self {
        Self {
            should_quit: false
        }
    }

    fn refresh_screen(&self) -> Result<(), std::io::Error> {
	print!("{}", termion::clear::All);
	print!("{}{}", termion::clear::All, termion::cursor::Goto(1, 1));
        io::stdout().flush()
    }

    pub fn run(&mut self) {
        let _stdout = stdout().into_raw_mode().unwrap();

        loop {
            if let Err(error) = self.refresh_screen() {
                panic!(error);
            };

            if self.should_quit {
                break;
            };

            if let Err(error) = self.process_keypress() {
                panic!(error);
            };

        }
    }

    fn process_keypress(&mut self) -> Result<(), std::io::Error> {
        let pressed_key = read_key()?;
        match pressed_key {
            Key::Ctrl('q') => self.should_quit = true,
            _ => (),
        }
        Ok(())
    }
}
```
Quitting the program was done by using the `panic!` macro, but that leaves an ugly output in stderr. `should_quit` is a bool, set to true when `ctrl+q` is pressed. If `should_quit` is true, exit program.

![Using panic! to exit](/images/hecto/using_panic_macro_to_exit.png){:class="img-responsive"}
<h5 style="text-align: center; font-style: italic;">Using panic! to exit</h5>

`termion::clear::All`, and `termion::cursor::Goto(1, 1)`. Clears the screen then goes to row 1, column 1.

the `process_keypress` has been condensed down, before the byte code and the character would printed in that function. Now it has `read_key` a helper function. Basically it grabs the current key pressed and returns it as an event. The `?` for when it's called is the same as calling `unwrap`. And if `pressed_key` matches `ctrl+q`, `should_quit` is set to `true`, quitting the program.

# Drawing tidles (~) like vim
First get the height of the terminal window a struct will represent this data. `termion` provides a method to get the width, and height of the terminal window.
```rust
pub struct Terminal {
    size: (u16, u16)
}

impl Terminal {
    pub fn new() -> Result<Self, std::io::Error> {
        let size = termion::terminal_size()?; // <- gets terminal dimensions
        let term = Self {
            size: (size.0, size.1)
        };

        Ok(term)
    }

    pub fn size(&self) -> (u16, u16) {
        (self.size.0, self.size.1)
    }
}
```
Add a new field to `Editor`
```rust
Editor {
    should_quit: bool,
    terminal: Terminal
}
```
Create a draw function
```rust
fn draw_tidles(&self) {
    for _ in 0..self.terminal.size.1 {
        println!("~\r");
    }
}
```
Then reset the cursor to `1, 1` after the call.
```rust
if self.should_quit {
    break;
} else {
    self.draw_tildes();
    print!("{}", termion::cursor::Goto(1, 1));
    io::stdout().flush();
}
```
*Moved all functions related to the terminal into the implementation of `Terminal`.*

# Touching up
```rust
    // moved `refresh_screen` back to editor.rs
    pub fn refresh_screen(&self) -> Result<(), std::io::Error> {
	Terminal::clear_screen();
        Terminal::cursor_hide();
        Terminal::cursor_position(0, 0);
        Terminal::flush()
    }
```
Clearing the screen each time is overkill, to fix it in the `draw_tildes` function, it should clear the current line instead. So when the window moves down, it doesn't just clear the entire screen.
```rust
    pub fn clear_current_line() {
        print!("{}", termion::clear::CurrentLine);
        Self::flush();
    }
```
Then in `draw_tildes`
```rust
    fn draw_tildes(&self) {
        for _ in 0..self.terminal.size().1 {
            Terminal::clear_current_line();
            println!("~\r");
        }
    }
```

# Displaying a welcome message
Drawing the welcome message will be called when the tidles are being drawn.
```rust
    fn draw_tildes(&self) {
        let height = self.terminal.size().1;
        for row in 0..height {
            Terminal::clear_current_line();
            if row == height / 3 {
                self.draw_welcome_message();
            } else {
                println!("~\r");
            }
        }
    }
```
```rust
    fn draw_welcome_message(&self) {
        let mut welcome_message = format!("Hecto -- version {}\r", VERSION);         
        let width = self.terminal.size().0 as usize;
        let len = welcome_message.len();

        let padding = width.saturating_sub(len) / 2;
        let spaces = " ".repeat(padding.saturating_sub(1));

        welcome_message = format!("~{}{}", spaces, welcome_message);
        welcome_message.truncate(width);

        println!("{}\r", welcome_message);
    }
```
To illustrate centering the text.
```
Assume the width of the screen in 24 chars
+------------------------+
|                        |
|                        |
+------------------------+
```
To center the text in the center with 4 chars, you must make space so `width - 4`.
This places the 4 character string right up to the edge of the screen.
```
+------------------------+
|                    TEXT|
|                        |
+------------------------+
```
Then half the length of the width which places the "T" in "TEXT" starting from the 12th character.
```
+------------------------+
|           TEXT         |
|                        |
+------------------------+
```
It's not exactly centered but close enough.
