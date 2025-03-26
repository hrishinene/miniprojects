from abc import ABC

from profilepoint.activity import profile

class SudoUnit(ABC):
    def __init__(self, numbers):
        if len(numbers) != 9:
            raise ValueError("Array must contain exactly 9 integers.")
        self.numbers = numbers

    def validate(self):
        """
        Abstract method to validate the array.
        Must be implemented by subclasses.
        """
        with profile("validate"):
            # if any of the number is less than 0 or greater than 9 return false 
            if any(num < 0 or num > 9 for num in self.numbers):
                return False
        
            # if any of the number except 0 is repeated, return false
            non_zero_numbers = [num for num in self.numbers if num != 0]
            if len(non_zero_numbers) != len(set(non_zero_numbers)):
                return False
        
            return True
    
    def __str__(self):
        return " ".join(str(num) for num in self.numbers)