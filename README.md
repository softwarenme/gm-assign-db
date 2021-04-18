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
