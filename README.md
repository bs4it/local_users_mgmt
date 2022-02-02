# local_users_mgmt
Manages Windows local user accounts for a set of servers defined in a txt file. It loops over these servers performing operations on the local user accounts, like creating, deleting and setting passwords.
It requites PowerShell 7 and a SSH environment set to use key based authentication between the manager node (where the script runs) and the managed servers.

