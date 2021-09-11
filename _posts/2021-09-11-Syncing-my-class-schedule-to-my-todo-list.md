---
layout: post
title:  "Syncing my class schedule to my todo list"
categories: one-shot
---

* TOC
{:toc}

---

# Why would I want to do that?
Well that's because the app provided by my school is really damn slow. I hate going to it whenever I want to check my schedule because its slow. Not because the app is poorly made. But it's because the app needs to process a JSON request that has over 20k entries. So I did some digging on the network tab in dev tools on firefox, and found the API that gives me all the timetable information.

# Implementation
The todo app I'm using is called todoist, it has an API as well and I use that to schedule all my tasks programatically. All I need to do is run the script, at the end of every week and I'll have my schedule all planned out. In todoist I create a new label called "Classes" where I schedule all tasks related to my classes. So I need to assign that label to all the tasks created this way, and I need the label id for that. So I'm going to get it through this function. I of course have the API URI that my school uses, and my todoist api key as environment variables for obvious reasons, and for more obvious reasons this repo will not be available on github. In fact it's local.

```python
def get_labels(label_name):
    """Gets the label id from the a label"""
    labels = (label for label in requests.get("https://api.todoist.com/rest/v1/labels", headers=headers).json())

    label_id = 0
    for label in labels:
        if label["name"] == label_name:
            label_id = label["id"]

    return [label_id]
```

Next I get the dates of all of my tasks that have been scheduled already
```python
def get_all_tasks(label_id):
    """Returns that dates of the scheduled tasks that matches the label id"""
    dates = []
    params = {"label_id": label_id}
    tasks = requests.get(
            "https://api.todoist.com/rest/v1/tasks",
            params=params,
            headers=headers).json()

    for task in tasks:
        dates.append(task["due"]["date"])

    return dates
```

Next I make a request to my school's API, to get all the information about my classes, the name of it, the lecturer, what time, the module code, etc. Then I pack it all into a dicitonary and return it.
```python
def prepare_tasks() -> dict :
    """Prepares the tasks to be scheduled by putting them into a dictionary."""
    today = date.today()
    uri = APU_URI
    lectures = (item for item in requests.get(uri).json())

    classes_on = []
    valid_lectures = []
    for lecture in lectures:
        intake = lecture["INTAKE"]
        grouping = lecture["GROUPING"]

        if grouping == "G3" and intake == "UCDF2104ICT(SE)":
            class_on = datetime.strptime(lecture["DATESTAMP_ISO"], "%Y-%m-%d").date()
            classes_on.append(class_on)
            valid_lectures.append(lecture)

    return {"class_on": classes_on, "lectures": valid_lectures}
```

Then I check to see if that task has already been scheduled. If it has it will be removed from the list.
```python
def if_scheduled(class_info, scheduled_tasks):
    """Makes sure that tasks that are already schduled don't get scheduled again.
    Returns a generator that contains the tasks that needs to be scheduled."""
    classes_on = class_info["class_on"]

    today = date.today()
    classes_on.sort()
    scheduled_tasks.sort()

    len_class_on = len(classes_on)
    len_scheduled_tasks = len(scheduled_tasks)
    if len_class_on != len_scheduled_tasks:
        diff = max(len_scheduled_tasks, len_class_on) - min(len_scheduled_tasks, len_class_on)
        for padding in range(diff):
            scheduled_tasks.append(0)

        counts = []
        counter = 0 
        for class_on, scheduled_task in zip(classes_on, scheduled_tasks):
            if scheduled_task == 0:
                continue 

            scheduled_task = datetime.strptime(scheduled_task, "%Y-%m-%d").date()
            if class_on == scheduled_task:
                counts.append(counter)

            counter += 1

        counts.sort(reverse=True)
        for count in counts:
            classes_on.pop(count)

    lectures = class_info["lectures"]
    for (class_on, lecture) in zip(classes_on, lectures):
        has_class_passed = not (class_on <= today) 
        has_been_scheduled = True

        if has_class_passed:
            class_name = lecture["MODID"]
            lecturer = lecture["NAME"]
            start_time = lecture["TIME_FROM"]
            end_time = lecture["TIME_TO"]

            item = {"class_name": class_name, "lecturer": lecturer, "start_time": start_time, "end_time": end_time, "date": class_on}
            yield item
```

Then finally this returns all the tasks that I need to schedule. Which I can finally call the todoist api to schedule them.
```python
def schedule_tasks(lessons, label_id: list):
    """Schedules a task"""
    task_no = 1
    for lesson in lessons:
        class_name = lesson["class_name"]
        lecturer = lesson["lecturer"]
        date = lesson["date"]
        start_time = lesson["start_time"]

        data = requests.post(
            "https://api.todoist.com/rest/v1/tasks",
            data=json.dumps({
                "content": f"{class_name} by {lecturer}",
                "due_string": f"{date} at {start_time}",
                "label_ids": label_id
            }),
            headers={
                "Content-Type": "application/json",
                "X-Request-Id": str(uuid.uuid4()),
                "Authorization": f"Bearer {TODOIST_API_KEY}"
            })

        if data.ok:
            print(f"Number of tasks scheduled: {task_no}")
            task_no += 1

    print("Tasks scheduled.")
```

This will then schedule everything in my todolist app programatically.
![Final outcome](/images/UniSyncSchedule/final_product.png){:class="img-responsive"}
And this is the final outcome. I've censored the names of my lecturers of course.

