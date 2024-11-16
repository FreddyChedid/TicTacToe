from flask import Flask, jsonify, request
import random

app = Flask(__name__)

board = [['' for _ in range(4)] for _ in range(4)]
turn = 'X'

def check_win(player):
    for i in range(4):
        if all(cell == player for cell in board[i]):  # Rows
            return True
        if all(board[j][i] == player for j in range(4)):  # Columns
            return True
    if all(board[i][i] == player for i in range(4)) or all(board[i][3 - i] == player for i in range(4)):  # Diagonals
        return True
    return False

def check_draw():
    return all(all(cell != '' for cell in row) for row in board)

def make_computer_move(level):
    if level == 'Random':
        return easy_move()
    elif level == 'Minimax Easy':
        return depth_limited_minimax_move(0)  # Depth of 0 for easy
    elif level == 'Minimax Medium':
        return depth_limited_minimax_move(1)  # Depth of 1 for medium
    elif level == 'Minimax Hard':
        return depth_limited_minimax_move(4)  # Depth of 4 for hard
    elif level == "Expectimax":
        return expectimax_move(3)  # Depth of 3 for expectimax
    else:
        return easy_move()

def easy_move():
    empty_cells = [(r, c) for r in range(4) for c in range(4) if board[r][c] == '']
    return random.choice(empty_cells) if empty_cells else None

def evaluate_board(b):
    def count_lines(player):
        lines = 0
        for i in range(4):
            if all(cell == player or cell == '' for cell in b[i]):  # Rows
                lines += 1
            if all(b[j][i] == player or b[j][i] == '' for j in range(4)):  # Columns
                lines += 1
        if all(b[i][i] == player or b[i][i] == '' for i in range(4)):  # Diagonal
            lines += 1
        if all(b[i][3 - i] == player or b[i][3 - i] == '' for i in range(4)):  # Anti-diagonal
            lines += 1
        return lines
    return count_lines('O') - count_lines('X')

# Depth-limited Minimax with Alpha-Beta Pruning
def depth_limited_minimax_move(max_depth):
    best_score = float('-inf')
    best_move = None
    alpha = float('-inf')
    beta = float('inf')
    for r in range(4):
        for c in range(4):
            if board[r][c] == '':
                board[r][c] = 'O'
                score = minimax(board, 0, max_depth, False, alpha, beta)
                board[r][c] = ''
                if score > best_score:
                    best_score = score
                    best_move = (r, c)
                alpha = max(alpha, score)
    return best_move

def minimax(b, depth, max_depth, is_maximizing, alpha, beta):
    if check_win('O'):
        return 8 - depth
    if check_win('X'):
        return depth - 8
    if check_draw() or depth >= max_depth:
        return evaluate_board(b)

    if is_maximizing:
        max_eval = float('-inf')
        for r in range(4):
            for c in range(4):
                if b[r][c] == '':
                    b[r][c] = 'O'
                    eval = minimax(b, depth + 1, max_depth, False, alpha, beta)
                    b[r][c] = ''
                    max_eval = max(max_eval, eval)
                    alpha = max(alpha, eval)
                    if beta <= alpha:
                        break
        return max_eval
    else:
        min_eval = float('inf')
        for r in range(4):
            for c in range(4):
                if b[r][c] == '':
                    b[r][c] = 'X'
                    eval = minimax(b, depth + 1, max_depth, True, alpha, beta)
                    b[r][c] = ''
                    min_eval = min(min_eval, eval)
                    beta = min(beta, eval)
                    if beta <= alpha:
                        break
        return min_eval

# Expectimax with Depth Limitation
def expectimax_move(max_depth):
    best_score = float('-inf')
    best_move = None
    for r in range(4):
        for c in range(4):
            if board[r][c] == '':
                board[r][c] = 'O'
                score = expectimax(board, 0, max_depth, False)
                board[r][c] = ''
                if score > best_score:
                    best_score = score
                    best_move = (r, c)
    return best_move

def expectimax(b, depth, max_depth, is_maximizing):
    if check_win('O'):
        return 8 - depth
    if check_win('X'):
        return depth - 8
    if check_draw() or depth >= max_depth:
        return evaluate_board(b)

    if is_maximizing:
        max_eval = float('-inf')
        for r in range(4):
            for c in range(4):
                if b[r][c] == '':
                    b[r][c] = 'O'
                    eval = expectimax(b, depth + 1, max_depth, False)
                    b[r][c] = ''
                    max_eval = max(max_eval, eval)
        return max_eval
    else:
        total_eval = 0
        move_count = 0
        for r in range(4):
            for c in range(4):
                if b[r][c] == '':
                    b[r][c] = 'X'
                    eval = expectimax(b, depth + 1, max_depth, True)
                    b[r][c] = ''
                    total_eval += eval
                    move_count += 1
        return total_eval / move_count if move_count > 0 else 0

@app.route('/move', methods=['POST'])
def make_move():
    global turn
    data = request.get_json()
    row, col = data['row'], data['col']
    level = data['level']

    if board[row][col] != '':
        return jsonify({'status': 'invalid', 'message': 'Invalid move'})

    board[row][col] = 'X'

    if check_win('X'):
        response = {'status': 'win', 'winner': 'X', 'board': board, 'turn': ''}
        reset_board()
        return jsonify(response)

    if check_draw():
        response = {'status': 'draw', 'board': board, 'turn': ''}
        reset_board()
        return jsonify(response)

    turn = 'O'
    comp_move = make_computer_move(level)
    if comp_move:
        comp_row, comp_col = comp_move
        board[comp_row][comp_col] = 'O'

    if check_win('O'):
        response = {'status': 'win', 'winner': 'O', 'board': board, 'turn': ''}
        reset_board()
        return jsonify(response)

    if check_draw():
        response = {'status': 'draw', 'board': board, 'turn': ''}
        reset_board()
        return jsonify(response)

    turn = 'X'
    return jsonify({'status': 'next', 'turn': 'X', 'board': board})

@app.route('/reset', methods=['POST'])
def reset_board():
    global board, turn
    board = [['' for _ in range(4)] for _ in range(4)]
    turn = 'X'
    return jsonify({'status': 'reset', 'turn': turn})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
