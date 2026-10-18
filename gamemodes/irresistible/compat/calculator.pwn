// Bounded expression parser for /calc: + - * / % ^, unary signs and parentheses.
enum e_Error { ERROR_NONE, ERROR_SYNTAX, ERROR_DIVISION, ERROR_DEPTH };
stock CalcSkipSpace(const expression[], &cursor)
{
    while (expression[cursor] == ' ' || expression[cursor] == '\t') cursor++;
}
stock Float:CalcExpression(const expression[], &cursor, &e_Error:error, minimum = 0, depth = 0)
{
    if (depth > 32) { error = ERROR_DEPTH; return 0.0; }
    CalcSkipSpace(expression, cursor);
    new Float:left;
    if (expression[cursor] == '+' || expression[cursor] == '-') {
        new sign = expression[cursor++];
        left = CalcExpression(expression, cursor, error, 3, depth + 1);
        if (sign == '-') left = -left;
    } else if (expression[cursor] == '(') {
        cursor++;
        left = CalcExpression(expression, cursor, error, 0, depth + 1);
        CalcSkipSpace(expression, cursor);
        if (expression[cursor] != ')') { error = ERROR_SYNTAX; return 0.0; }
        cursor++;
    } else {
        new start = cursor, digits = 0;
        while (expression[cursor] >= '0' && expression[cursor] <= '9') { cursor++; digits++; }
        if (expression[cursor] == '.') {
            cursor++;
            while (expression[cursor] >= '0' && expression[cursor] <= '9') { cursor++; digits++; }
        }
        if (!digits) { error = ERROR_SYNTAX; return 0.0; }
        new number[72];
        strmid(number, expression, start, cursor, sizeof number);
        left = floatstr(number);
    }
    while (error == ERROR_NONE) {
        CalcSkipSpace(expression, cursor);
        new op = expression[cursor], precedence;
        switch (op) {
            case '+', '-': precedence = 1;
            case '*', '/', '%': precedence = 2;
            case '^': precedence = 3;
            default: break;
        }
        if (!precedence || precedence < minimum) break;
        cursor++;
        new Float:right = CalcExpression(expression, cursor, error, precedence + (op == '^' ? 0 : 1), depth + 1);
        if (error != ERROR_NONE) return 0.0;
        switch (op) {
            case '+': left += right;
            case '-': left -= right;
            case '*': left *= right;
            case '/', '%': {
                if (right == 0.0) { error = ERROR_DIVISION; return 0.0; }
                if (op == '/') left /= right;
                else left -= float(floatround(left / right, floatround_tozero)) * right;
            }
            case '^': left = floatpower(left, right);
        }
    }
    return left;
}
stock Float:CalculateExpression(const expression[], &e_Error:error)
{
    new cursor = 0;
    error = ERROR_NONE;
    new Float:value = CalcExpression(expression, cursor, error);
    CalcSkipSpace(expression, cursor);
    if (expression[cursor]) error = ERROR_SYNTAX;
    return value;
}
