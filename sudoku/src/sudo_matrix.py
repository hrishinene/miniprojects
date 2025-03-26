import json

from profilepoint.activity import profile
from sudo_row import Row
from sudo_column import Column
from sudo_minimatrix import MiniMatrix

class Matrix:
    def __init__(self, array):
        if len(array) != 9 or any(len(row) != 9 for row in array):
            raise ValueError("Input must be a 9x9 2D array")
        self.data = array
        self.solveCount = 0

    def __repr__(self):
        return f"Matrix({self.data})"
    
    def getRows(self):
        return [Row(row) for row in self.data]
    
    def getColumns(self):
        columns = []
        for i in range(9):
            colmnValues = []
            for j in range(9):
                colmnValues.append(self.data[j][i])
                
            columns.append(Column(colmnValues))
           
        return columns
    
    def getMiniMatrices(self):
        with profile("getMiniMatrices"):
            matrices = []
            for i in range(3):
                for j in range(3):
                    matrixValues = []
                    for row in range(3):
                        for col in range(3):
                            matrixValues.append(self.data[i*3 + row][j * 3 + col])
                    
                    matrices.append(MiniMatrix(matrixValues))
            
        return matrices

    def validate(self):
        with profile("Row Validation"):
            rows = self.getRows()
            for row in rows:
                if not row.validate():
                    # print (f"Row failed to validate: {row}")
                    return False
            
        with profile("Column Validation"):
            columns = self.getColumns()
            for column in columns:
                if not column.validate():
                    # print (f"Column failed to validate: {column}")
                    return False
            
        with profile("Mini Matrix Validation"):
            miniMatrices = self.getMiniMatrices()
            for miniMatrix in miniMatrices:
                if not miniMatrix.validate():
                    # print (f"Minimatrix failed to validate: {miniMatrix}")
                    return False
            
        return True
    
    def __str__(self):
        matrix_str = "\n"
        for row in self.data:
            matrix_str += " ".join(str(num) if num != 0 else "." for num in row) + "\n"
        return matrix_str
    
    def solve(self):
        # put a number in the empty slot starting from beginning to end and keep validating till success!
        # Back tracking algorithm
        self.solveCount += 1
            
        for i in range(9):
            for j in range(9):
                if (self.data[i][j] == 0):
                    num = 1
               
                    # Now recurse till we get the valid matrix 
                    for num in range(1,10):
                        self.data[i][j] = num
                        # print(f"Setting {i},{j} to {num}")
                        if (self.validate()):
                            if (self.solve()):
                                return True
                    
                    self.data[i][j] = 0
                    return False
                    
        return True