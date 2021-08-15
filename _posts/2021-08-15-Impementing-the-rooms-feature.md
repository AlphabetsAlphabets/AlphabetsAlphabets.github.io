---
layout: post
title: Implementing the rooms feature
---

# Implementation of rooms
1. Create a room with a topic name.
2. The ability to make a room private, or public. And inviting in users if the room's visibilty has been set to private.
3. Deleting the room

The first part is already done.
```python
    async def create_new_room(self, ctx, name):
        guild = ctx.guild

        categories = guild.categories
        category_name = ""
        for category in categories:
            if category.name == "Rooms":
                category_name = category
                break

        topic = f"{ctx.author.name} would like to discuss about {name}."
        channel = await guild.create_text_channel(name, topic=topic, category=category_name)
        return channel
```
By passing in the context, and the name of the person who created to room. A new text channel under the room category will be created with a designated topic that always follows the format `"<author> would like to discuss about <topic>"`

The ability to make a room private, or public is also done.
```python
make_private = False
if args[-1].lower() == "true":
    del args[-1]
    make_private = True

channel = await self.create_new_room(ctx, name)
role = await self.make_room_owner(ctx, channel)

if make_private:
    await channel.set_permissions(everyone, view_channel=False)
    await channel.set_permissions(role, view_channel=True)
```
However the ability to change visiblity does not yet exist. It may be implemented in the future. If the visiblity of the room has been set to private, the owner of the room will be able to give a role to his/her friends or whoever they want to have a private discussion with a role, that grants access for the other members to join into the private room.
