import random

random_numbers = [random.randint(60, 240) for _ in range(17)]
random_numbers_str = ', '.join(str(x) for x in random_numbers)
result_str = f'({random_numbers_str})'

print(result_str)
