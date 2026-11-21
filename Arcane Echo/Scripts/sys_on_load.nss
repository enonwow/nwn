#include "lib_echo_def"
#include "sql_echo"

void main()
{
    EchoCreateTables();
    // Prune expired traces from previous sessions
    EchoDecayAll(ECHO_DECAY_HOURS);
}
