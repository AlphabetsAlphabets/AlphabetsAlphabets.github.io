---
title : 'Difficulties when making a lexer.'
date : 2024-03-02
series: ['Moon']
series_order: 2
---

## Problem 1: Not understanding what a lexer is.
I thought a lexer was called a parser. So, my lexer did the tokenization and evaluation. Not good. What's more the "parser" was completely [garbage](https://github.com/AlphabetsAlphabets/Moon/blob/b20479efdedc4c81636e783a20415b0bbbab555c/src/parser.c#L55-L100) it looks absolutely disgusting.

The lexer is responsible for producing tokens from source code. The parser will structure the tokens. Then interpreter will traverse the AST and be responsible for code execution.

## Problem 2: Unfamiliarity with C.
1. I forgot about `*foo` and `foo[0]`[^array-things]

```c
 void print_token(Scanner *scanner) { 
     Token token = *scanner->tokens; 
     for (int i = 0; token.type != END_OF_FILE; i++) { 
         ...
         printf("%s ('%c') at line %i\n", name, *lexeme, token.line); 
         token = scanner->tokens[i]; 
     }
 }
 ```

I created a variable for the specific token using 

```c
Token token = *scanner->tokens; 
```

and then I printed it out at the bottom and then used the `i` to get the next element. What's the problem? `*scanner->tokens` is the same as `scanner->tokens[i]`. This means that I'll print the value at index `0` *twice*. This resulted in my thinking something was wrong with my lexer, when it was completely fine. It was a logic error in a completely different location.

## Problem 3: General carelessness[^array-things]
1. I forgot about the order of operations.

When allocating an array to store my tokens I did it like this.

```c
scanner->tokens = malloc(sizeof(Token) * length_of_src + 1)
```

The problem is that it allocates space for `length_of_src` number of Tokens and 1 more byte. This oversight casued so much issue down the line.

```c
scanner->tokens = malloc(sizeof(Token) * (length_of_src + 1))
```

The fix was the add brackets to give the `length_of_src + 1` operation a higher precedence.

2. `char* foo` vs `char foo`.[^string-issue]

At some point I had to add multi-lexeme tokens to the lexer. For example, `>=` is considered as one token not `>` and `=` separately. When I printed the tokens this is how I did it.

```c
char *lexeme = token.lexeme; 
printf("%s ('%c') at line %i\n", name, *lexeme, token.line);
```

First, `char* lexeme` is a c-string. This is fine because `token.lexeme` is of type `char *`. At this point in time, my lexer only supports single character lexemes. As such the persepective I had was `char *` is a pointer to a character not a pointer to an array of characters. This was enough to cause me lots of issues as I was wondering how I should handle cases where lexemes would be single characters long and when they would be multiple.

Arrays can have either no elements, a single element, or as many as you want. Therefore, if `char* lexeme = "c"`. It just means that `lexeme` has only one element in it. In other words, it is a **string** with one character. Then I came to the realisation that I can just print the string in it's entirety, which resulted in this:

```c
printf("%s ('%s') at line %i\n", name, lexeme, token.line);
```

Which completely fixed my issues.

[^array-things]: https://github.com/AlphabetsAlphabets/Moon/issues/4#issuecomment-1898499536
[^string-issue]: https://github.com/AlphabetsAlphabets/Moon/pull/8
