import random

def generate_tambola_ticket():
    """
    Generates a standard 3x9 Tambola ticket.
    - 3 rows, 9 columns
    - Each row has exactly 5 numbers and 4 blanks
    - Column 1: 1-9
    - Column 2: 10-19
    - Column 3: 20-29
    - Column 4: 30-39
    - Column 5: 40-49
    - Column 6: 50-59
    - Column 7: 60-69
    - Column 8: 70-79
    - Column 9: 80-90
    - Numbers in a column must be sorted in ascending order from top to bottom
    """
    # Initialize 3x9 grid with zeros
    ticket = [[0 for _ in range(9)] for _ in range(3)]
    
    # Column ranges
    ranges = [
        list(range(1, 10)),
        list(range(10, 20)),
        list(range(20, 30)),
        list(range(30, 40)),
        list(range(40, 50)),
        list(range(50, 60)),
        list(range(60, 70)),
        list(range(70, 80)),
        list(range(80, 91))
    ]
    
    # Track how many numbers are placed in each column and row
    col_counts = [0] * 9
    row_counts = [0] * 3
    
    # Step 1: Ensure each column has at least 1 number
    for c in range(9):
        num = random.choice(ranges[c])
        ranges[c].remove(num)
        
        # Place it in a random row
        placed = False
        while not placed:
            r = random.randint(0, 2)
            if ticket[r][c] == 0 and row_counts[r] < 5:
                ticket[r][c] = num
                row_counts[r] += 1
                col_counts[c] += 1
                placed = True
                
    # Step 2: Fill the remaining 6 numbers (15 total - 9 placed)
    # The remaining numbers can go to any column, but no column can exceed 3
    # and no row can exceed 5.
    remaining = 6
    while remaining > 0:
        c = random.randint(0, 8)
        if col_counts[c] < 3:
            # Find a valid row
            valid_rows = [r for r in range(3) if ticket[r][c] == 0 and row_counts[r] < 5]
            if valid_rows:
                r = random.choice(valid_rows)
                num = random.choice(ranges[c])
                ranges[c].remove(num)
                ticket[r][c] = num
                row_counts[r] += 1
                col_counts[c] += 1
                remaining -= 1
                
    # Step 3: Sort columns top to bottom
    for c in range(9):
        nums_in_col = []
        for r in range(3):
            if ticket[r][c] != 0:
                nums_in_col.append(ticket[r][c])
        nums_in_col.sort()
        
        idx = 0
        for r in range(3):
            if ticket[r][c] != 0:
                ticket[r][c] = nums_in_col[idx]
                idx += 1
                
    return ticket

def test_ticket():
    ticket = generate_tambola_ticket()
    for row in ticket:
        print([n if n != 0 else ' ' for n in row])

if __name__ == '__main__':
    test_ticket()
