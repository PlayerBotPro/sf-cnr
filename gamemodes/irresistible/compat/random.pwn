// MT19937 for the casino MRandom calls, kept in source instead of a legacy DLL.
static mt_state[624], mt_index = 624, bool:mt_seeded;
stock SeedMRandom(seed)
{
    mt_state[0] = seed;
    for (new index = 1; index < 624; index++)
        mt_state[index] = 1812433253 * (mt_state[index - 1] ^ (mt_state[index - 1] >>> 30)) + index;
    mt_index = 624;
    mt_seeded = true;
}
stock MRandom(limit)
{
    if (limit <= 1) return 0;
    if (!mt_seeded) {
        SeedMRandom(GetTickCount() ^ gettime());
    }
    new value, ceiling = 0x7FFFFFFF - (0x7FFFFFFF % limit);
    do {
        if (mt_index >= 624) {
            for (new i = 0; i < 624; i++) {
                new y = (mt_state[i] & 0x80000000) | (mt_state[(i + 1) % 624] & 0x7FFFFFFF);
                mt_state[i] = mt_state[(i + 397) % 624] ^ (y >>> 1) ^ ((y & 1) ? 0x9908B0DF : 0);
            }
            mt_index = 0;
        }
        value = mt_state[mt_index++];
        value ^= value >>> 11;
        value ^= (value << 7) & 0x9D2C5680;
        value ^= (value << 15) & 0xEFC60000;
        value ^= value >>> 18;
        value >>>= 1;
    } while (value >= ceiling);
    // Avoid the stock AMX interpreter's large-divisor remainder overflow.
    if (value < limit) return value;
    if (value - limit < limit) return value - limit;
    return value % limit;
}
