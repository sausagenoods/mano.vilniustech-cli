# mano.vilniustech-cli
Made by reverse engineering the Mano VGTU Android app. Shove it into a conky, shove it into a cron, now it's all yours.

## Examples
Get today's schedule: `./mano.vilniustech.sh lecture-schedule today`

Get this week: `./mano.vilniustech.sh lecture-schedule`\
Example output `$cachedir/lecture_schedule`:
```
Monday     10:20-11:55  Computer Architecture                           ER-I 421
Monday     14:30-16:05  Philosophy                                      SRK-II 205
Monday     16:20-17:55  Discrete Mathematics 2                          SRA-I A01
Tuesday    12:10-13:45  Speciality English Language                     SRL-I 410
Tuesday    14:30-16:05  Object-Oriented Programming (with course work)  SRL-I 420
Tuesday    16:20-17:55  Discrete Mathematics 2                          SRK-II 301
Wednesday  12:10-13:45  Object-Oriented Programming (with course work)  SRA-I A01
Wednesday  14:30-16:05  Computer Architecture                           ER-I 407
Wednesday  16:20-17:55  Computer Architecture                           ER-I 407
```
Get x semester, y week: `./mano.vilniustech.sh lecture-schedule x y`

Get exam results: `./mano.vilniustech.sh exam-results`

For more options run the script without arguments or read the source code.
