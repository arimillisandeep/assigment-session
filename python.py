1.Given number of minutes, convert it into human readable form.
Example :
130 becomes “2 hrs 10 minutes”
110 becomes “1hr 50minutes”
  

minutes = int(input(""))

hours = minutes // 60
remaining_minutes = minutes % 60

if hours > 0:
    print(f"{hours} hrs {remaining_minutes} minutes")
else:
    print(f"{remaining_minutes} minutes")


2.You are given a string, remove all the duplicates and print the unique string.Use loop in the python.
text = input()

unique_string = ""

for char in text:
    if char not in unique_string:
        unique_string += char

print(unique_string)
