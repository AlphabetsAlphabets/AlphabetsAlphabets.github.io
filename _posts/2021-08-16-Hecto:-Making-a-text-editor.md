---
layout: post
title: "Hecto: Making a text editor"
categories: hecto
---

* TOC
{:toc}

---


# Cargo.toml specifications
```toml
[package]
name = "hecto"
version = "0.1.0"
edition = "2018"

[dependencies]
termion = "1"
unicode-segmentation = "1"
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

# Creating the editor
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

## Drawing tidles (~) like vim
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

## Touching up
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

## Displaying a welcome message
Drawing the welcome message will be called when the tidles are being drawn.
```rust
    fn draw_tildes(&self) {
        let height = self.terminal.size().1;
        for row in 0..height - 2 {
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

# Functionality
## Moving the cursor
Making the cursor move means in the places where `Terminal::cursor_position` was called and set to `(0, 0)` is now pointless. That function will now that a `Position` as an argument. `Position` will be in `editor.rs` and **not** `terminal.rs` because it's the position of the cursor **in the document**, not in the terminal.

```rust
    pub fn cursor_position(pos: &Position) {
        // using `saturating_add` prevents the buffer from overflowing.
        let Position { mut x, mut y } = pos;
        let x = x.saturating_add(1) as u16;
        let y = y.saturating_add(1) as u16;

        print!("{}", termion::cursor::Goto(x, y));
        Self::flush();
    }
```
Next creating `Position` in `editor.rs`
```rust
pub struct Position {
    pub x: usize,
    pub y: usize,
}
```
Detecting the key press will be done in the `process_keypress` function (lmao obviously).
```rust
    fn process_keypress(&mut self) -> Result<(), std::io::Error> {
        let Position { mut x, mut y } = self.cursor_position;
        let pressed_key = Terminal::read_key()?;
        match pressed_key {
            Key::Ctrl('q') => self.should_quit = true,
            Key::Up | Key::Down | Key::Left | Key::Right => self.move_cursor(pressed_key),
            _ => (),
        }
        Ok(())
    }
```

A new method in `Editor` called `move_cursor` will be implemented. The cursor will be able to move any where within the bounds of the screen.
```rust
    fn move_cursor(&mut self, key: Key) {
        let Position { mut x, mut y } = self.cursor_position;

        let size = self.terminal.size();
        let width = size.width.saturating_sub(1) as usize;
        let height = size.height.saturating_sub(1) as usize;

        match key {
            Key::Up => y = y.saturating_sub(1),
            Key::Down => {
                if y < height {
                    y = y.saturating_add(1)
                }
            },
            Key::Left => x = x.saturating_sub(1),
            Key::Right => {
                if x < width {
                    x = x.saturating_add(1)
                }
            },
            _ => (),
        }

        self.cursor_position = Position { x, y }
    }
```
<h5 style="text-align: center; font-style: italic;">(0, 0) starts in the top left corner, not the centre of the screen.</h5>

```rust
            if self.should_quit {
                Terminal::clear_screen();
                Terminal::cursor_show();
                break;
            } else {
                self.draw_tildes();
                Terminal::cursor_position(&self.cursor_position);
            }
```
The change here is that instead of setting the cursor to `(0, 0)` after drawing the tidles (which is every single time unless it's to quit hecto). Will cause the cursor to not move despite the functions being implemented. The fix is to just move the cursor to the current position of the cursor which doesn't change where it is at all.

## Adding modes (5010ba7)
A struct that has the different modes will be used. `PartialEq` will save me from using too many match statements.
```rust
#[derive(PartialEq)]
enum Mode {
    Insert,
    Normal
}
```

Made two functions to handle the inputs in normal and insert mode.
```rust
    fn normal_mode(&mut self, key: Key) {
        let Position { mut x, mut y } = self.cursor_position;

        let size = self.terminal.size();
        let width = size.width.saturating_sub(1) as usize;
        let height = size.height.saturating_sub(1) as usize;

        match key {
            Key::Char('k') => y = y.saturating_sub(1),
            Key::Char('j') => {
                if y < height.saturating_sub(1) {
                    y = y.saturating_add(1)
                }
            }
            Key::Char('h') => x = x.saturating_sub(1),
            Key::Char('l') => {
                if x < width {
                    x = x.saturating_add(1)
                }
            }

            Key::Char('i') => {
                self.mode = Mode::Insert;
            }
            _ => (),
        }

        self.cursor_position = Position { x, y }
    }

    fn insert_mode(&mut self, key: Key) {
        match key {
            Key::Esc => {
                self.mode = Mode::Normal;
            }
            _ => (),
        }
    }
```

The move cursor function will need to be modified
```rust
    fn move_cursor(&mut self, key: Key) {
        if self.mode == Mode::Normal {
            self.normal_mode(key);
        } else {
            self.insert_mode(key);
        }
    }
```

To switch between different modes the `process_keypress` function will be modified
```rust
    fn process_keypress(&mut self) -> Result<(), std::io::Error> {
        let Position { mut x, mut y } = self.cursor_position;
        let pressed_key = Terminal::read_key()?;
        match pressed_key {
            Key::Ctrl('q') => self.should_quit = true,
            Key::Char('j') | Key::Char('k') | Key::Char('l') | Key::Char('h') => {
                self.move_cursor(pressed_key)
            }
            Key::Esc => self.change_mode(Mode::Normal),
            Key::Char('i') => self.change_mode(Mode::Insert),
            _ => (),
        }
        Ok(())
    }
```

`change_mode` will change the mode (lmao yeah duh)
```rust
    fn change_mode(&mut self, change_to: Mode) {
        self.mode = change_to;
    }
```

## Adding in 0 and S
Very simple change in `process_keypress` modify the match arm that uses `move_cursor`
```rust
            Key::Char('j') | Key::Char('k') | Key::Char('l') | Key::Char('h') 
                |  Key::Char('0') | Key::Char('S') => {
                self.move_cursor(pressed_key)
            }
```
In the `normal_mode` function add these arms
```rust
            Key::Char('0') => x = 0,
            Key::Char('S') => x = width,
```
Since `g` goes to the beginning of the file, set y to 0, same reasoning for `0` the start of the line is when x is 0. When going to the bottom of the screen with `G` y is set to `height`.

# Viewing files
In `document.rs` a new function `open` is to be defined, it's going to open a file.
```rust
    pub fn open(filename: &str) -> Self {
        let contents = fs::read_to_string(filename).expect("Unable to open file.");
        let mut rows = vec![];

	// lines() strips all whitespace characters at the end of each line.
        for value in contents.lines() {
            rows.push(Row::from(value));
        }

        Self { rows }
    }
```

This changes the `new` method for `Editor`
```rust
    pub fn new() -> Self {
        let args: Vec<String> = env::args().collect();
        let document = if args.len() > 1 {
            let file_name = &args[1];
            Document::open(file_name)
        } else {
            Document::default()
        };

        Self {
            mode: Mode::Normal,
            should_quit: false,
            document,
            terminal: Terminal::new().expect("Failed to initialize terminal."),
            cursor_position: Position::default(),
        }
    }
```
Checking if args is greater than 1 because `args[0]` is the name of the program, and `args[1]` onwards are actual arugments. If it's greater than 1 it means a file is passed in. And it will load the contents of that document into the editor, else it will load in an empty document into the editor.

To draw all of the text onto the screen.
```rust
impl Row {
    pub fn render(&self, start: usize, end: usize) -> String {
	// start will always be smaller than end due to `min`
        let end = cmp::min(end, self.string.len());
        let start = cmp::min(start, end);
        self.string.get(start..end).unwrap_or_default().to_string()
    }
}
```
This function will always make sure to return a substring (assuming `start`, and `end` are reasonable numbers). `get` can be used on `&str`, and `String` to get substrings.

In `draw_row` 
```rust
    fn draw_row(&self, row: &Row) {
        let start = 0;
        let end = self.terminal.size().width as usize;
        let row = row.render(start, end);

        println!("{}\r", row);
    }
```
`render` as discussed earlier will print extract a substring or return `None`, then print out the substring.

## Scrolling
### Vertical scrolling
a new field offset of type `Position` will need to be added to `Editor`
```rust
pub struct Editor {
    mode: Mode,
    offset: Position,
    should_quit: bool,
    document: Document,
    terminal: Terminal,
    cursor_position: Position,
}
```
This will be used to handle scrolling vertically (up and down). The value of `offset.x`, and `offset.y` will not be determined on startup. Instead it is initialized in the new `scroll` function.

```rust
    fn scroll(&mut self) {
        let Position { x, y } = self.cursor_position;
        let width = self.terminal.size().width as usize;
        let height = self.terminal.size().height as usize;
        let mut offset = &mut self.offset;

        if y < offset.y {
            offset.y = y;
        } else if y >= offset.y.saturating_add(height) {
            offset.y = y.saturating_sub(height).saturating_add(1);
        }

        if x < offset.x {
            offset.x = x;
        } else if x >= offset.x.saturating_add(width) {
            offset.x = x.saturating_sub(width).saturating_add(1);
        }
    }
```
`offset` keeps track of which row the user is at in the file. 

Assuming `y` is 24, and offset.y is 0, i the first `if` the second condition would be true. Then the added height is subtracted from `offset.y` and 1 is added to it. This will allow for scrolling, as `offset.y` is used in here to determine what lines should be drawn onto the screen:
```rust
if let Some(row) = self.document.row(terminal_row as usize + self.offset.y) {
    self.draw_row(row);
} else if self.document.is_empty() && terminal_row == height / 3 {
    self.draw_welcome_message();
} else {
    println!("~\r");
}
```
As the goal is to scroll downwards, the row that is obtained from the `row` method [^1] will be increased by 1, thereby ignoring the previous row, and rendering everything else instead. As the value of `offset.y` increases, the row that was rendered will be ignored in favour of a new one. The same concept is applied to scrolling horizontally. Where it ignores a character instead of an entire line.

### Horizontal scrolling
Horizontal scrolling is implemented this way.
```rust
let mut width = if let Some(row) = self.document.row(y) {
    row.len()
} else {
    0
};
```
This is used to determine the width of the line, meaning how many characters long it is. If the width cannot be determined set it to 0, as `row` functions by getting the index. Right now the cursor can move any where in the document, but it can only move as far as the longest row. If there is a row shorter than the longer row, it will be able to move beyond the width of the current row.

The fix for this is checking if the x position of the cursor is greater than the width of the current row. If it is set the x position to the width, to make sure the cursor can only move as far as right as the length of the current row.

```rust
// adjusts the width the the length of the row
width = if let Some(row) = self.document.row(y) {
    row.len()
} else {
    0
};

if x > width {
    x = width + 1; // <-- `width + 1` not in the guide
}
```

### Adding a fix
Because the cursor position has the values of `offset.x`, and `offset.y` added to it's value. It will need to be subtracted from it. So in `run()` in `editor.rs`

```rust
loop {
    if self.should_quit {
    	self.terminal.clear_screen();
    	break;
    } else {
    	self.draw_rows();
    	let pos = Position {
	    x: self.cursor_position.x.saturating_sub(self.offset.x),
	    y: self.cursor_position.y.saturating_sub(self.offset.y),
    	};
    
    	self.terminal.cursor_position(&pos);
    }
    
    if let Err(error) = self.process_keypress() {
    	panic!(error);
    };
}
```

## Adding in more keys
The W and B key in vim moves the cursor forward, and backward respectively until the first non whitespace character with the exception of the whitespace the cursor is currently on, or adjacent to.

### Adding in the 'w' key
In `normal_mode`, another match arm is added
```rust
if let Some(row) = self.document.row(y) {
	if let Some(contents) = row.contents().get(x..) {
		let mut index = 0;
		for (count, ch) in contents.chars().enumerate() {
			if !ch.is_ascii_alphabetic() {
				index = count;
				break;
			}
		}

		if x >= width && y < height {
			y += 1;
			x = 0;
		} else {
			x = x.saturating_add(index + 1);
		}

	}
}
```
`contents` is a simple function that returns the text in the current row. And `get`, gets a substring of that row. To illustrate:  

```
# See more {k}eys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html
```
Take this line, and the cursor position is found by finding what text is surrounded by {foo}, in this case the cursor is at the 'k' character in 'keys'. To move forward and stop at the first **non ascii alphabet**, excluding the word the cursor is at, looping through each character with `enumerate`. Taking note of `count`, and setting it to `index`. Because `count` is the number of characters that has passed to read the non ascii alphabetic character. 

The if statement at the bottom will allow the cursor to move to the start of the second line, assuming the cursor is at the end of the current line, and there is a next line (`y < height` part). Then increment y by 1, and set x to 0 (the start of the line). If that isn't the case, then just add the number of characters passed into the current x position to move it.

And the 'b' is the reverse of the 'w' so it won't be specified in here, the concepts are all the same. [^2]

### Scrolling up and down a page.
The keys responsible for this will be captial 'J', and 'K'. The comments I added is all the explanation that is needed.

#### The 'K' key
```rust
Key::Char('K') => {
	// first if only happens on the 1st screen.
	y = if y > terminal_height {
		// saturating_add/sub not used because y and terminal_height
		// have the same type.
		y - terminal_height
	} else {
		0
	}
}
```

#### The 'J' key
```rust
Key::Char('J') => {
	// terminal_height is the number of visible rows on the screen.
	// height is the number of rows in the entire file
	y = if y.saturating_add(terminal_height) < height {
		y + terminal_height as usize
	} else {
		// This is only true when it's at the last page
		height
	}
}
```

# Drawing a status bar
One new field will need to be added. That is the `file_name` field.
```rust
pub struct Editor {
    // Editing
    mode: Mode,
    file_name: String,
    // Editor
    /// Keeps track of which row the file the user is currently on.
    offset: Position,
    should_quit: bool,
    document: Document,
    terminal: Terminal,
    cursor_position: Position,
}
```
Line in vim, it shows the file name of the file we are currently working on. And the status bar will also display the current mode.

There will also need to be a change in the `new` related method for `Editor`
```rust
    pub fn new() -> Self {
        let args: Vec<String> = env::args().collect();
        let mut file_name = "";
        let document = if args.len() > 1 {
            file_name = &args[1];
            Document::open(&file_name).unwrap_or_default()
        } else {
            Document::default()
        };

        Self {
            mode: Mode::Normal,
            offset: Position::default(),
            file_name: file_name.to_string(),
            should_quit: false,
            document,
            terminal: Terminal::new().expect("Failed to initialize terminal."),
            cursor_position: Position { x: 0, y: 0 },
        }
```
The change is to create a new variable to store the current file name. The mode struct will be moved into it's own file. And implement display on it, so nothing verbose will stay in this file.

```rust
impl fmt::Display for Mode {
    fn fmt(&self, f:&mut fmt::Formatter<'_>) -> fmt::Result {
        let mode = match self {
            Self::Insert => "INSERT",
            Self::Normal => "NORMAL",
            Self::Command => "COMMAND",
        };

        write!(f, "MODE: {}", mode)
    }
}
```

The next step is to simply print it all out.
```rust
    fn draw_status_bar(&mut self) {
        let status = format!("{} | {}", self.mode, self.file_name);
        println!("{}", status);
    }
```

Next we need to decrease the size of the screen, thereby limit the areas where the cursor can go. In the `Terminal` struct.
```rust
impl Terminal {
    pub fn new() -> Result<Self, std::io::Error> {
        let size = termion::terminal_size()?;
        let term = Self {
            size: Size {
                width: size.0,
                height: size.1.saturating_sub(2),
            },
            stdout: stdout().into_raw_mode()?,
        };

        Ok(term)
    }
}
```
Reduce the height by 2 because:
1. Make space for the status bar 
2. Make space for below the status bar.

In the `draw_rows` function there isn't a need to subtract the height by 1 anymore.
```rust
fn draw_rows(&mut self) {
    ...
    for terminal_row in 0..height {
        ...
    }
}
```

[Previously](https://github.com/YJH16120/hecto/blob/913d49300816dae5e370f6ddef04588e1d370a0d/src/editor.rs#L257), the solution was to prevent the cursor from going to the line the status bar was, and to stop it from going past it. But all that did was prevent scrolling. It never occured to me to reduce the size of the active area instead. 

The next thing to do would be to colour it. And make it pretty.
```rust
    fn draw_status_bar(&mut self) {
        let status = format!("{} | {}", self.mode, self.file_name);
        let spaces = " ".repeat(self.terminal.size().width as usize - status.len());

        self.terminal.set_bg_color(STATUS_BAR_BG_COLOUR);
        self.terminal.set_fg_color(STATUS_FG_COLOUR);
        println!("{}{}\r", status, spaces);
        self.terminal.reset_fg_color();
        self.terminal.reset_bg_color();
    }
```
This code will draw the status bar horizontally along the line it is supposed to be in, and in colour as well thanks to terminal. Since `reset_fg_color`, `reset_bg_color`, `set_bg_color`, and `set_fg_color` are simple implementations, their details will be found in the foot notes [^3]

As for repeating the spaces, that is to pad it out. If the result of `status` is 7 characters long, the status bar would only be 7 characters long. The spaces is to pad it out making the status bar a horizontal bar.

The next thing to do would be to add an indicator to tell the user which line he is currently on.
```rust
    fn draw_status_bar(&mut self) {
        let width = self.terminal.size().width as usize;
        let filename = if let Some(filename) = self.file_name.get(..21) {
            filename.to_string()
        } else {
            self.file_name.clone()
        };

        let status = format!("{} | {}", self.mode, filename);

        let rows = self.document.len() as f32;
        let current_line = (self.cursor_position.y + 1) as f32;

        let percentage = if rows > 0.0 {
            (current_line / rows * 100.0).trunc()
        } else {
            0 as f32
        };

        let line_number = format!("{}/{}: {}%", current_line, rows, percentage);
        let spaces = " ".repeat(width - status.len() - line_number.len());

        self.terminal.set_bg_color(STATUS_BAR_BG_COLOUR);
        self.terminal.set_fg_color(STATUS_FG_COLOUR);
        println!("{}{}{}\r", status, spaces, line_number);
        self.terminal.reset_fg_color();
        self.terminal.reset_bg_color();
    }
```
There is quite a lot of new stuff here. So to break it down line by line
1. Getting the width and setting it for future use.
2. Getting the filename up to the 20th character. Just incase it gets too long. There is a chance that the file name is less than 21 characters which results in an error. So and `if let` statement is used in case of an error, it will just use the file name.
3. Getting the status to have the current mode, and it's filename.
4. Getting the rows, and current line. The reasons one is added to it is because at the very first line, the y pos of the cursor is 0 this is so that it can working with the `row` method easier.
5. Calculating the percentage of lines passed.
6. Formatting everything nicely, with colours.

While there is a bug that adds in an extra line into the document and it gets processed as an actual line by Hecto despite the line not existing inside of the original file, on top of that the cursor will be able to move to, and past the status bar. The way to fix this is like so:
```rust
Key::Char('J') => {
    // terminal_height is the number of visible rows on the screen.
    // height is the number of rows in the entire file
    y = if y.saturating_add(terminal_height) < height.saturating_sub(1) {
        y + terminal_height as usize
    } else {
        // This is only true when it's at the last page
        height.saturating_sub(1)
    }
}
```
By adding in `height - 1`. This stops the cursor from moving to, and past the status bar. And fixes the extra "phantom" line that was added in by Hecto. I noticed that when using captial J in normal mode, the cursor could go past the bounds of the document, but that did not apply to lower case j in normal mode, so I just did the samething for captial J as well.

# Text editing
## Typing
Finally after all the setup just for viewing text, Hecto is ready to become at least some what similar to a text editor. Hecto needs to know that we are currently typing, so in the `process_keypress` function:
```rust
    fn process_keypress(&mut self) -> Result<(), std::io::Error> {
        let pressed_key = Terminal::read_key()?;
        match pressed_key {
            Key::Esc => self.change_mode(Mode::Normal),
            Key::Char('i') => {
                if self.mode == Mode::Insert {
                    self.insert_mode(pressed_key)
                } else {
                    self.command_mode(pressed_key)
                }
            }
            Key::Char(':') => self.change_mode(Mode::Command),
            _ => self.check_mode(pressed_key),
        }

        self.scroll();
        Ok(())
    }
```
Just like in vim, you'll need to be in INSERT mode before you can type, else everything you do will be strictly for navigation.

After switching to insert mode, it'll need to detect all characters regardless of what it is so you can type, therefore: 
```rust
    fn insert_mode(&mut self, key: Key) {
        match key {
            Key::Esc => self.change_mode(Mode::Command),
            Key::Char(c) => {
                self.document.insert(c, &self.cursor_position);
                self.normal_mode(Key::Char('l'));
            }

            _ => (),
        }
    }
```

An `insert` function needs to be implemented for `Document`
```rust
    pub fn insert(&mut self, c: char, at: &Position) {
        if self.rows.is_empty() {
            let c = c.to_string();
            let row = Row::from(c);
            self.rows.push(row);
        } else {
            let row = self.rows.get_mut(at.y).unwrap();
            row.insert(at, c);
        }
    }
```
The way it works is if the rows are empty, meaning you either didn't open a file, or you opened a file but it has no text in it, the first if condition will trigger. Adding a row so you can type into an empty file. If it is not added, you will not be able to type, because Hecto will outright crash. Since that condition can only trigger once, it'll function like a normal text editor.

This function is a simple one, if the y position (`at.y`) of the cursor is less than the length of the doucment, insert character at `at.x`.

The `Row` struct needed an `insert` function as well.
```rust
    pub fn insert(&mut self, at: usize, c: char) {
        if at >= self.len {
            self.string.push(c);
        } else {
            let mut result: String = self.string[..].graphemes(true).take(at).collect();
            let remainder: String = self.string[..].graphemes(true).skip(at).collect();
            result.push(c);
            result.push_str(&remainder);
            self.string = result;
        }
        self.update_len();
    }
```
In order to call `graphemes(true)` the `UnicodeSegmentation`[^4] crate is needed, it has already been included in `Cargo.toml` file. It is also available in the specifications. If the cursor is greater than or equal to the length, meaning if it is at the end of the line, or further than that (which isn't possible, but, it's nice to cover all basis) simply add that character to the end of the line.

If it was however somewhere in the middle of the line, cut the string into two and push the character to the first half of the string, then stitch them back together. `update_len` is very simple, does exactly what the name suggests:
```rust
    fn update_len(&mut self) {
        self.len = self.string[..].graphemes(true).count();
    }
```

```rust
Key::Char(c) => {
    self.document.insert(c, &self.cursor_position);
    self.normal_mode(Key::Char('l'));
}
```
Where `normal_mode` is called, this is to move the cursor to the right. Because without it text would appear, but, the cursor would not move, but instead, remain at the same position.

## Enter key - Adding a new line
Since the enter key produces a newline character `\n`, having that being detected is enough. So in the match arm where all characters are detected in `insert_mode`
```rust
Key::Char(c) => {
    if c == '\n' {
        self.document.enter(&self.cursor_position);
        self.normal_mode(Key::Char('j'));
        self.normal_mode(Key::Char('0'));
    } else {
        self.document.insert(c, &self.cursor_position);
        self.normal_mode(Key::Char('l'));
    }
}
```
`Key::Char('0')` will make sure the cursor moves to the very beginning of the line just like how the cursor would normally function. `Key::Char('j')` is to make the cursor go down first.

The `enter` function looks like this:
```rust
pub fn enter(&mut self, at: &Position) {
    self.insert_newline(at);
}

fn insert_newline(&mut self, at: &Position) {
    let new_row = self.rows.get_mut(at.y).unwrap().split(at.x);
    self.rows.insert(at.y + 1, new_row);
}
```
`enter` will serve as a sort of entry way into the `insert_newline` function. You will first get the current row, then split it's contents at where the cursor is, and you want the second half of the contents, meaning everything to the right of the cursor, and stick that in a new row.

The `split` function will handle splitting the text of the row with the cursor as a center.
```rust
pub fn split(&mut self, at: usize) -> Self {
    let beginning: String = self.string.graphemes(true).take(at).collect();
    let remainder: String = self.string.graphemes(true).skip(at).collect();

    self.string = beginning;
    self.update_len();
    Self::from(&remainder[..])
}
```

## Deleting text
After inserting text you need to know how to delete text, so, there will be a new match arm, detecting the backspace key.
```rust
fn insert_mode(&mut self, key: Key) {
    match key {
        Key::Esc => self.change_mode(Mode::Command),
        Key::Backspace => {
            self.document.backspace(&self.cursor_position);
            self.normal_mode(Key::Char('h'));
        }
        Key::Char(c) => {
            if c == '\n' {
                self.document.enter(&self.cursor_position);
                self.normal_mode(Key::Char('j'));
                self.normal_mode(Key::Char('0'));
            } else {
                self.document.insert(c, &self.cursor_position);
                self.normal_mode(Key::Char('l'));
            }
        }

        _ => (),
    }
}
```

The call to `normal_mode` and `Key::Char('h')` is to move the cursor backwards, because the cursor doesn't say on the same place as you type. As for the logic itself it is a pretty long one and with good reason! Took me a while to come up with this one, and I've started to divludge from the guide very heavily at this point. With the way I'm going to implement command mode, it's gonna take a hard left turn to where I can't follow the guide anymore.
```rust
    pub fn backspace(&mut self, at: &Position) {
        let current_row = self.rows.get_mut(at.y).unwrap();

        if current_row.string.len() == 0 {
            // removing rows
            self.rows.remove(at.y);
        } else if at.x == 0 {
            // removing rows
            let current_row = self.rows.get_mut(at.y).unwrap();
            let contents = current_row.contents();

            let mut row_above_current = self.rows.get_mut(at.y.saturating_sub(1)).unwrap();
            row_above_current.string = format!("{}{}", row_above_current.string, contents);

            self.rows.remove(at.y);
        } else {
            // removing the text from the row
            let current: String = current_row
                .string
                .graphemes(true)
                .take(at.x.saturating_sub(1))
                .collect();

            let remainder: String = current_row.string.graphemes(true).skip(at.x).collect();

            let new_row = format!("{}{}", current, remainder);
            let new_row = Row::from(new_row);
            *current_row = new_row;
        }
    }
```
I'm going to breakdown the explanation by if statements. So first up is the very sort if statement:
```rust
if current_row.string.len() == 0 {
    // removing rows
    self.rows.remove(at.y);
}
```
This is when you use backspace the end of an empty line, and the total number of lines decreases, and everything below that line moves upwards. It was originally a hell of a lot longer I would include a footnote, but, I didn't put it into a commit because I managed to find a built in function from the standard library. Next up:

```rust
else if at.x == 0 {
    // removing rows
    let current_row = self.rows.get_mut(at.y).unwrap();
    let contents = current_row.contents();

    let mut row_above_current = self.rows.get_mut(at.y.saturating_sub(1)).unwrap();
    row_above_current.string = format!("{}{}", row_above_current.string, contents);

    self.rows.remove(at.y);
} 
```
This is when you use backspace at the start of the line and there are characters in that line. This will append the contents of the previous line to the line above. I get the content of the current line and I stored it in `contents`, then I get the row above so I can modify that row's contents, I do that with `row_above_current.string = format!("{}{}", row_above_current.string, contents);` Then I remove the current row the cursor is one. Reducing the total number of lines by 1.

Last but not least is using backspace to delete a character.
```rust
else {
    // removing the text from the row
    let current: String = current_row
        .string
        .graphemes(true)
        .take(at.x.saturating_sub(1))
        .collect();

    let remainder: String = current_row.string.graphemes(true).skip(at.x).collect();

    let new_row = format!("{}{}", current, remainder);
    let new_row = Row::from(new_row);
    *current_row = new_row;
}
```
By only collecting the text up to `at.x.saturating_sub(1)`, and collecting everything else skipping `at.x` characters, then combining them together to form a new row, then change the current row with the updated row which is the one with deleted text.

The way `take` works is that it will take all elements up to `x` but not including `x`. For example:
```rust
let x = vec![1, 2, 3, 4, 5];
let x = x.iter().take(2);
// x = [1, 2];
```

But `skip` will skip all characters up to and **including** `x`.
```rust
let x = vec![1, 2, 3, 4, 5];
let x = x.iter().skip(2);
// x = [3, 4, 5];
```

Assuming the same vectors in both examples are used. Taking the same amount but minus it by one.
```rust
let x = x.iter().take(2 - 1);
// x = [1];
```

Then skipping for the same amount.
```rust
let x =x .iter().skip(2);
// x = [3, 4, 5];
```

My taking away one character, you essentially delete it. And that's how the backspace key works.

## Tabs
Since I am used to spaces, instead of tabs this editor will be converting all tabs to spaces, and it's also because it's a lot easier to implement spaces instead. In `edito.rs`, and `insert_mode`, in the match arm, just add in four spaces, and call to insert mode. This will make the cursor move accordingly, and such.
```rust
Key::Char(c) => {
    if c == '\n' {
        self.document.enter(&self.cursor_position);
        self.normal_mode(Key::Char('j'));
        self.normal_mode(Key::Char('0'));
    } else if c == '\t' {
        self.insert_mode(Key::Char(' '));
        self.insert_mode(Key::Char(' '));
        self.insert_mode(Key::Char(' '));
        self.insert_mode(Key::Char(' '));
    } else {
        self.document.insert(c, &self.cursor_position);
        self.normal_mode(Key::Char('l'));
    }
}
```

# Saving files (or writing files)
These two functions are needed, first you open the file that is currently being edited with write privelleges, and you truncate it. That's what the `truncate_and_open_file` function does, as the name would suggest.
```rust
fn truncate_and_open_file(&self) -> Result<fs::File, std::io::Error> {
    let mut file = fs::OpenOptions::new();
    file.write(true)
        .truncate(true)
        .open(&self.filename)
}
```

Next would be to save the file itself. Because when you truncate the file, and newline characters don't get inserted into the document directly they need to be appended here:
```rust
pub fn save_file(&mut self) {
    if let Ok(mut file) = self.truncate_and_open_file() {
        for row in &self.rows {
            let string = format!("{}\n", row.string);
            file.write_all(string.as_bytes()).unwrap();
        }
    }     
}
```

The reason to truncate the file is so that you make sure the contents are as fresh as possible, this also avoids duplicating text. In a previous iteration of this function, the number of newline characters would increase because the file was not truncated before hand, making the file longer and longer each time. But when opened in Hecto they looked fine[^5]. But this solution fixes the issue. With this Hecto has now become a function text editor with good features! It is usable but I plan to add mroe features to it. I plan to extend the Hecto blog posts instead of having one gigantic post. Who knows, I might keep it as one gigantic post anyways.

# Footnotes
[^1]: The `row` method will index into the `Row` struct which has a field containing a vector of strings, where each element is a row in a file, then grab that role using the provided index.

[^2]: [The implementation of the 'b' key](https://github.com/YJH16120/hecto/blob/master/src/editor.rs#L143)

[^3]: [The colour changing stuff](https://github.com/YJH16120/hecto/blob/94813bfbf66d5b9f0b0b644f4a520d37e4d9ff1f/src/terminal.rs#L66).

[^4]: The reason the UnicodeSegmentation crate is used is because scrolling is determined via bytes, but some characters have larger bytes which can lead to improper deletion or scrolling of text, for example arabic characters. That crate is used to solve that issue.

[^5]: [This issue persisted for a very long time](https://github.com/YJH16120/hecto/blob/9ae7913395984310be97c380a38d589445314aaa/src/document.rs#L94)
