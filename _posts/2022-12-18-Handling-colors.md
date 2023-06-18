---
layout: post
title: "Handling colors in tags"
tags: actt 
---

So, in Actt and many other applications you can assign tags colors. The purpose is to let you see what you have going on, and it is also a very nice visual distinction. Who wouldn't love that? It works one of two ways.
1. The tag exists, meaning it already has a color associated with it. So, the color automatically shifts to that color.
2. The tag doesn't exist. It's new. A new color can be assigned. This behaviour is also based on user preferences which I have yet to fully implement. I may write a blog post about the whole thing in the future.

I had to go through three different iterations to find a fix. The first iteration.
```rust
if let Some(color_index) = tag_list_iter.position(|e| *e == app.tag_name) {
    let color = app.config.colors[color_index];
    let color_exist = !(app.find_color(list_of_colors, &color) == usize::MAX);

    if color_exist {
        color = app::random_color(list_of_colors, &color, None);
    }
}
```

It's nice and simple. Finds the index of the tag. The way the index works is that in the config file the index of tags matches the index of colors.
```
tags: [Sports, Reading, Relaxation]
color: [Red, Green, Blue]
```

Because they match, the index used for `tags` would be the same for `colors` and vice versa. This does not fulfill the first condition, that if a tag exists assign the associated color. It does work for number 2. So, after some simple tweaks, it got me the second iteration. It was really simple.

```rust
if let Some(color_index) = tag_list_iter.position(|e| *e == app.tag_name) {
    let mut color = app.config.colors[color_index];
    let color_exist =
        !(app.find_color(list_of_colors, &color) == usize::MAX);

    if color_exist {
        color = app::random_color(&list_of_colors, &color, None);
    }

    app.color = color; // <-- this is the only new line.
}
```

This works fine. If the color exists, check if the color the user has selected exists through `random_color`.
```rust
pub fn random_color(
    &self,
    list_of_colors: &[Color32],
    color: &Color32,
    count: Option<usize>,
) -> Color32 {
    let limit = 256 ^ 3;
    let count = count.unwrap_or(0) + 1;
    let limit_not_reached = !(limit == count);
    let color_exists = self.does_color_exist(list_of_colors, color);

    if color_exists && limit_not_reached {
        let r = rand::thread_rng().gen_range(0..=255);
        let g = rand::thread_rng().gen_range(0..=255);
        let b = rand::thread_rng().gen_range(0..=255);

        self.random_color(list_of_colors, &Color32::from_rgb(r, g, b), Some(count))
    } else {
        color.clone()
    }
}
```

`random_color` returns the color passed in if it doesn't exist. Otherwise, it will recursively find new color combinations until it finds one that doesn't exist. The limit of `usize::MAX` can be reach, but that doesn't mean it *will* be reached. You would need `16,777,216` unique tags to reach that limit. So, it's a pretty safe bet. So, if the color does exist, then cool, it will have the associated color. How is that handled? Through this field.

> This is the part where it will be difficult. I didn't document *everything* like I did with Hecto. So, I'll most likely skip through some things. The source code is available on GitHub.

```rust
#[derive(serde::Deserialize, serde::Serialize)]
#[serde(default)] // if we add new fields, give them default values when deserializing old state
    ...
    pub color: Color32,
}

```

Because `#[serde(skip)]` doesn't apply to `color`. That means the matching color will be applied on start up. Aside from the first boot. The problem here, is that what's stopping `random_color` from being called over and over again? The place where this code resides is in `start_screen`, and egui the crate I'm using to develop the user interface uses immediate mode. Which means that when you launch on start up, `color` already exists in the config file. Which means that a random color will be called. 

> You'd expect this call to only happen one time. But for some reason it doesn't, the color picker just flips outs and the UI reflects this by constantly changing the color of the picker everytime the UI updates. Which is whenever you move your move, or press a key on your keyboard (even if nothing is actually being entered).

So the fix is the 3rd iteration (it's actually more than 3, 3 just sounds nice, lol).

```rust
ui.columns(2, |column| {
    column[0].vertical_centered_justified(|ui| ui.label("Tag color"));
    column[1].vertical_centered_justified(|ui| {
        color_picker_color32(ui, &mut app.color, Alpha::Opaque);
        let tag_index =
            app.config.find_tag(&app.config.tag_list, &app.tag_name);
        let tag_exist = tag_index == usize::MAX;

        if !tag_exist {
            app.color = app.config.colors[tag_index];
        }

        let does_color_exist =
            app.config.does_color_exist(&list_of_colors, &app.color);

        if tag_exist && does_color_exist {
            app.color =
                app.config.random_color(&list_of_colors, &app.color, None);
        }
    });
});
```

The code was moved into the same scope where the color picker is handled. This makes sure that the color only gets updated, if the color picker is interacted with. The color flipping still happens without the proper checks, it's just more neat if I move it in here since everything is bundled together. Ok, the part that stops the color flipping is this. 

```rust
if tag_exist && does_color_exist {
    app.color = app.config.random_color(&list_of_colors, &app.color, None);
}
```

If the tag does **not** exist.

> remember if `tag_index == usize::MAX` returns `true`, that means the tag **doesn't** exist.

And the color does exist, then and only then can you generate a random color. If the tag exists, no reason to generate a random color because an associated color already exists. If the color does exist, and the tag doesn't exist. There's no reason for you to create a color for a tag that doesn't exist. Only if both don't exist can you create a tag and a color for it.   

That's about it for handling colors. I'll be sure to document the sunburst. That seems pretty fun, and interesting given the amount of circle math I'll have to do. I may or may not also have frequent updates on user preferences. In any case this marks the completion of the tags feature. The sunburst utilizes tags, but, that is its own thing and deserves its own branch.
