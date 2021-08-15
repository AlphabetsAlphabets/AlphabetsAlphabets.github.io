---
layout: post
title:  "Understanding the lexer"
categories: Notes about source
---

# Lexer
The lexer is the `Scanner` struct defined in scanner.rs. It's job is to go through each character in a lox source file, and create tokens from each of those characters. Depending on context it can determine if the token is supposed to be a '>=' (`GreaterEqual`), or just a '>' (`Greater`). It also needs to differentiate between strings, and integers. In my version of rlox, there is only the number type there is no difference between integers, and floats.

Currently there are 4 reserved keywords (that can't actually do anything yet as nothing has been implemented for it). And the four are:
1. var
2. and
3. else
4. class

# How does the lexer create the correct token.
If the lexer goes through the source code of lox and finds a '>' character it could just give it the `Greater` token but if the next character is a '=', the token should be `GreaterEqual`. This is done with helper functions.

The `match` function and the `if_contains` function will work together.
{% highlight rust %}
fn r#match(&mut self, expected: char) -> bool {
	if self.is_at_end() {
	    false
	} else if self.advance() != expected {
	    false
	} else {
	    self.current += 1;
	    true
	}
}

fn if_contains(&mut self, expected: char, v1: TokenType, v2: TokenType) -> TokenType {
	if self.r#match(expected) {
	    v1
	} else {
	    v2
	}
}
{% endhighlight %}
`if_contains` will look forward by one character to check if the next character is the `expected` character. If the next character in the source file matches `expected` it will return `v1`, else it will return `v2`. The `match` function is the one responsible for looking forward into the source file by one. There are a few useful fields used by the scanner, because the scanner needs to know where it is in the source file among all the characters.

{% highlight rust %}
Scanner {
    source,
    tokens: vec![],
    column: 0,
    current: 0,
    line: 1,
}
{% endhighlight %}
These are all the fields the scanner has access to. The names are self-explanatory except for `current`. `current` helps the scanner keep track of where it is at in the entire source file. If `current` is 100 it means the scanner is looking at the 100th character in the source code.
