app_sim(n) Automated Test Suite
----------------------------------------------------------------------

This directory contains the automated test suite for app_sim(n).  The
entire test suite is executed by the command line

    $ athena_test all

Individual test scripts can be executed as well.  See athena_test(1) for
details.

The following things should be covered by the test suite:

* Test utilities
* Simulation Orders
* Module mutators and queries
* Notifier Events

Note that the test suite explicitly does *NOT* cover the GUI.

The test suite files fall in numbered categories, to control
the order of execution.

001:     Test infrastructure
002-009: Application infrastructure
010:     Scenario and Simulation modules
020:     Simulation orders
030:     Athena Executive commands and functions
040:     Rule Sets
050:     appserver pages
