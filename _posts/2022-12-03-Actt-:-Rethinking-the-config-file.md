---
layout: post
title: "Rethinking the config file"
tags: actt
---

So, there is a big problem. This is what my config file currently looks like.

```
{"name":["JP"],"total_time":[{"secs":0,"nanos":664720704}],"color":[[126,105,204,255]],"tag":["School"],"tag_assign_behavior":"random"}
```

This is what happens when I remove an entry.

```rust
app.activity = app.read_config_file();

app.activity.name.remove(index);
app.activity.total_time.remove(index);
app.activity.color.remove(index);
app.activity.tag.remove(index);
app.activity.tag_assign_behavior = app.tag_assign_behavior.clone();

app.write_config_file();
```

The main issue is `app.activity.tag.remove(index);`. Everything works off on indexes. I noticed that when all entries are cleared, all the tags are missing. Which is pretty obvious, given how everything is structured. Problem is, I didn't notice this until just a few days ago as of writing this. Which means, I'll need to rework the *entire* config file. This includes the code that I've been using in order to extract information from it, as well as the code that is used to write data into the config file. There were also a few functions I created specifically for showing exactly what the user needs. There are a lot more pros than cons when revamping the entire config file. It's just going to be a huge headache that's come to bite me now.

First let's talk about the structure of the config file. Every entry has it's own
1. Name.
2. Color.
3. Tag.

What does this mean? If there are 2 entries, and they both have the same tag it means they have the same color. So, the color and tag are duplicated. This will make the file size, way too big. I just thought of this and didn't bother optimizing it and now there are a hole host of issues that are because of the structure of the config file.

What's the solution? Well, I thought of something like this.

```
{
  "name": ["Math", "Science", "Physics", "League"],
  "total_time": [300, 300, 300, 600],
  "tag": [0, 0, 0, 1],
  "user_created_tags": ["School", "Entertainment"],
  "colors": [[126,105,204,255], [255,255,255,255]]
}
```

This way the `tag` field is itself an index that can be used for everything. With the obvious exception being `total_time` but it can be easily dealt with (I assume). Now I need to make the relevant changes which will break *a lot* of things. There was another problem it quickly made me realise this is flawed. Having `tag` be an index is the worst thing I could have done. Let's say this is the current state of the config.

```
{
  "name": ["Math", "League"],
  "total_time": [300, 600],
  "tag": [0, 1],
  "user_created_tags": ["School", "Entertainment"],
  "colors": [[126,105,204,255], [255,255,255,255]]
}
```

Based on the code I wrote,

```rust
activity.name.remove(*tag_index);
activity.total_time.remove(*tag_index);
activity.colors.remove(*tag_index);
activity.tag_index.remove(*tag_index);
activity.tag_assign_behavior = app.tag_assign_behavior.clone();
```

When you remove the first item, `Math`. What remains is,

```
{
  "name": ["League"],
  "total_time": [600],
  "tag": [1],
  "user_created_tags": ["School", "Entertainment"],
  "colors": [[255,255,255,255]]
}
```

`colors` doesn't have an index of `1` only `0`. Which is the error. Then it lead me to wonder if there was a better way for me to structure this data.

```
{
    "name": {
        "Math": [0, 0],
        "Science": [0, 0],
        "League": [1, 1]
    },
    "total_time": [300, 300, 300],
    "tags": ["Study", "Games"],
    "colors": [[126,105,204,255], [255,255,255,255]]
}
```

This is more like it. Even if `Science` and it's respective entries are deleted, it doesn't make a difference. Another thing I realised was that nothing in `colors` is to be deleted __unless__ the tag itself is deleted. It took me three hours but I finally did it. There are new modifications to it[^1]. As promised, I needed to modify a lot of things. The main change here is the addition of the `Entry` struct, it's a handly little thing.

> This was suggested to me weeks ago by [dnaka](https://github.com/dnaka91) on my [stream](https://twitch.tv/Cerenitty), glad I managed to remember it. Otherwise, it would've taken me much longer to do the same things.

```rust
#[derive(Deserialize, Serialize, Default)]
pub struct Entry {
    pub name: String,
    pub tag_index: usize,
    pub color_index: usize,
}
```

This is it, one entry. The activity struct will contain a vector of entries which I can then modify when the user finished with an activity and would like it to be logged. 

```rust
if app.does_tag_exist(&act.tag_list, &app.tag_name) {
    let existing_tag_index = app.find_tag(&act.tag_list, &app.tag_name);
    let existing_color_index = app.find_color(&act.colors, &app.color);
    let new_entry = Entry::new(
        app.activity_name.clone(),
        existing_tag_index,
        existing_color_index,
    );
    act.entry.push(new_entry);
    act.total_time.push(app.total_time.unwrap().elapsed());
} else {
    act.colors.push(app.color.clone());
    let new_color_index = act.colors.len() - 1;
    act.total_time.push(app.total_time.unwrap().elapsed());

    let new_tag_index = act.tag_list.len();
    let entry =
        Entry::new(app.activity_name.clone(), new_tag_index, new_color_index);
    act.entry.push(entry);

    act.tag_list.push(app.tag_name.clone());
}
```

The biggest change are these lines. It used to look completely different[^2]. This is because of the introduction of `Entry`. But, compared to the previous version this definitely looks a lot cleaner. Along with a few utility functions as well. Revamping the entire config file is definitely a bonus. There are still other features that are broken, such as the tag options. Which involves a context menu opening up and allowing you to pick from various options. The menu doesn't show up. But, one step at a time.

[^1]: The json is lengthy despite only having two entries which is why it is located in a paste, [here](https://paste.rs/Flq.json)
[^2]: Checkout the [diff](https://github.com/AlphabetsAlphabets/actt/commit/b22ec46ed622a3df2f2a738b766f2951c9ea1ee6?diff=unified#diff-2e19f9d4cc615159e143104182f5d0a39c3ee720b1907e17e69c690981859197L249), you may need to scroll up.
