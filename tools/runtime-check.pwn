#include <a_samp>
#include "../gamemodes/irresistible/compat/random.pwn"
#include "../gamemodes/irresistible/compat/calculator.pwn"

new failures;
stock CheckExpression(const expression[], Float:expected, e_Error:expected_error = ERROR_NONE)
{
    new e_Error:error;
    new Float:actual = CalculateExpression(expression, error);
    if (error != expected_error || (error == ERROR_NONE && floatabs(actual - expected) > 0.001)) {
        printf("[RUNTIME CHECK] FAIL expression: %s (%.3f, error %d)", expression, actual, _:error);
        failures++;
    }
}
main() {}
forward StopTestServer();
public StopTestServer() { SendRconCommand("exit"); }
public OnGameModeInit()
{
    CheckExpression("2+3*4", 14.0);
    CheckExpression("(2+3)*4", 20.0);
    CheckExpression("2^3^2", 512.0);
    CheckExpression("-2^2", -4.0);
    CheckExpression(".5 + 1.25", 1.75);
    CheckExpression("10 % 3", 1.0);
    CheckExpression("1/0", 0.0, ERROR_DIVISION);
    CheckExpression("1+", 0.0, ERROR_SYNTAX);
    CheckExpression("(1+2", 0.0, ERROR_SYNTAX);
    CheckExpression("1abc", 0.0, ERROR_SYNTAX);
    // Published MT19937 seed 5489 vector, shifted to nonnegative Pawn cells.
    SeedMRandom(5489);
    new expected[] = {1749605806, 290934651, 1945173367};
    for (new sample = 0; sample < sizeof expected; sample++) {
        new result = MRandom(0x7FFFFFFF);
        if (result != expected[sample]) {
            printf("[RUNTIME CHECK] FAIL random vector: %d expected %d", result, expected[sample]);
            failures++;
        }
    }
    new buckets[37];
    for (new i = 0; i < 10000; i++) {
        new result = MRandom(37);
        if (result < 0 || result >= 37) failures++;
        else buckets[result]++;
    }
    for (new i = 0; i < sizeof buckets; i++) if (!buckets[i]) failures++;
    if (MRandom(0) || MRandom(1)) failures++;
    printf("[RUNTIME CHECK] Completed: %d failures", failures);
    SetTimer("StopTestServer", 50, false);
    return 1;
}
