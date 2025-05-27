import sys

def convert_string_to_numbers(string):
    result = []
    for char in string:
        if char.isalpha():
            result.append(str(ord(char.lower()) - 96))
        else:
            result.append(char)
    return ' '.join(result)

if len(sys.argv) > 1:
    string = sys.argv[1]
    print(convert_string_to_numbers(string))
else:
    raise Exception()
