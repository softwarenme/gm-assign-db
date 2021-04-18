### **Problem Statement**

If you're not familiar with the Gumroad overlay, you should be. It's pretty cool: [gumroad.com/widgets](http://gumroad.com/widgets)

It's one line of HTML that includes some JavaScript that makes Gumroad links work inline on the page instead of send the user to gumroad.com/l/...

The way it works is pretty simple: it scans every link to a gumroad product on a page, and if they exist, turns them into inline popups using transparent iFrames. Implement your own version of this, that could also be included as a single JS file. It should be as performant as possible, and replicate as closely as possible Gumroad's functionality (i.e. It should look for links to Gumroad products, it should embed the Gumroad products themselves too and allow purchase, etc).

If you have time, please support:

- Custom subdomains and domains for creators (e.g. sahil.gumroad.com/pencil, sahil.com/pencil)
- Early-load pages upon hover
- Read data-attrs of the anchor tags to show a button or not, make it embed or not, etc.

If you have product feedback as well, we'd love to hear it!

### Database design

![DbDesign](https://user-images.githubusercontent.com/82768433/115153069-9c6ca500-a091-11eb-9226-2ac42de19413.jpg)


### Implementation details

Implmeneted a working database model using Rails bug reporting template.

It has following implemented changes

- Uses `sqlite3` databse
- Rails `ActiveRecord` models for the entities.
- Rails migrations for the tables related to the models.
- A Service to process payout to eplain the working.
- A test cases for the pauout service.

#### Database Index
Databse indexes are added on the columns to make the frequent database queries performant even for the large amount of data.

### How to test the changes?

Run following command from the repository root folder.

```
ruby data_model.rb
```

It will run the service test cases.

### What to check?

Along with the database modeling, there is a working service to demonstrate how the database model will be used to process the payout for a seller.

The test covers following scenarios

- Default payout schedule to pay every other week as explained in the problem statement.
- Weekly payout schedule.
- Custom payout schedule
