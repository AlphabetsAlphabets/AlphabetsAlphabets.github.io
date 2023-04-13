---
layout: post
title: "Custom error types: How to implement them and why."
---

Having custom error types is something that's really nice when you're trying to create a library or some sort of back end you plan to use in your future projects which is exactly what I did and for the purposes of this post I'm going to use it as an example. If you're curious the create is called [srsa](https://github.com/AlphabetsAlphabets/srsa/blob/master/src/errors.rs#L11).

Other than what I just mentioned why would you want to implement a custom error type? (1) Enables the use of `?` for error propagation and (2) it helps the end user understand the error better.

A little bit about `?`. `?` converts `Result<T, E>` into `E` meaning if a `Result<T, D>` is returned `?` won't work. The compiler will throw an error along the lines of "`D` can't be converted to `E`." To illustrate when this scenario will pop up take a look at this snippet [`retrieve_keys`](https://github.com/AlphabetsAlphabets/srsa/blob/master/src/lib.rs#L64).

> If you'd like to know what the `?` operator does *in detail*, please refer to another post.

```rust
// Get *encrypted* private key first
let mut pem = fs::read_to_string(priv_key_path)?;

// Decrypt encrypted private key
let priv_key = RsaPrivateKey::from_pkcs8_encrypted_pem(&pem, password)?;
pem.clear();

// Then get public key
pem = fs::read_to_string(pub_key_path)?;
let pub_key = RsaPublicKey::from_public_key_pem(&pem)?;
```

Let's look at the return types of functions where the `?` operator is used.
1. `fs::read_to_string` returns `io::Error`
2. `RsaPrivateKey::from_pkcs8_encrypted_pem(&pem, password)` returns `pkcs8::Error`.
3. `RsaPublicKey::from_public_key_pem(&pem)` returns `spki::Error`.

All three return differing `Result` types. This is where implementing your own error type comes in handy. Since this is a library crate, it's a good idea to let your end users know exactly what error they're dealing with.

A custom error type is just an enum with different variants for each error. This is the implementation of `KeyError`.
```rust
pub enum KeyError {
    KeyNotFound(String),
    PrivateKeyDecryptionFailed(String),
    PemDecryptionFailed(String),
}
```

It is plenty obvious what is going on to the user. But, how do you convert one error type to another? By implementing the `From` trait to `KeyError`. This is how I handle an `io::Error`

> For more detail about `From` or how it works please take a look at the [docs](https://doc.rust-lang.org/std/convert/trait.From.html).

```rust
impl From<io::Error> for KeyError {
    fn from(value: io::Error) -> Self {
        Self::KeyNotFound(value.to_string())
    }
}
```

It's very simple and all it does is get the message in the `io::Error` and put it inside `Self::KeyNotFound`. I do this for all the implementations of `From`. Lastly, you'll need to show that information somehow. If someone prints the error it won't work and you'll need to implement the `Display` or `Debug` trait.

When you implement the `Display` trait give the end user information just describe the error. As for the `Debug` trait, give precise information about the error itself so the developer knows what to do. But, in my case the implementation for `Debug` and `Display` are the same since there wasn't any additional information that could be convey.

```rust
impl Debug for KeyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        use KeyError::*;

        let msg = match self {
            KeyNotFound(msg) => format!("Key not found: {msg}"),
            PrivateKeyDecryptionFailed(msg) => format!("Key decryption failed: {msg}"),
            PemDecryptionFailed(msg) => format!("Pem decryption failed: {msg}"),
        };

        write!(f, "{}", msg)
    }
}
```
