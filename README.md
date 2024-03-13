# foundry-client
Hastly put together client for the FOUNDRY server. 
Use it with care.

## What is FOUNDRY?

I'm not allowed to disclose this information for fear of retaliation, but I hope you can use this tool to find it for yourself.

I've managed to build a quick-and-dirty RESTful API for FOUNDRY before leaving the company.
I checked the policies and since I used an admin ticket to create this tool, it tecnically does not breach the company guidelines to leave this running.
I'm sure this loophole will not be enough, but it should keep legal in a pinch for long enough that as many people as possible can have time to go through their files.
I don't know how long it will stay up before they notice and terminate the resource, but it should be harmless enough that it won't raise any alerts.

To facilitate access to the server I've built this client using a BASH script.
You can use it to login into the servers and navigate through the data.

In order to make it compliant with the guidelines, the server is protected by accounts levels and you'll need sufficient access to reach any and all of the data.
I cannot disclose any of the credentials for the servers, however **I'd recommend reading through the files on the bugs folder**.

## Accessing their servers

Run the `backdoor.sh` script and use it to login into one of the servers (you'll will need an account with sufficient clearance to be able to connect).

Auth tokens are valid for 60 minutes, after which you'll need to re-authenticate.

Once logged into one of the servers you'll have access to the documents stored in it.
There are many files to see, such as emails, logs, official docs, etc.
It should help you piece together what FOUNDRY is and what it is doing.
Use the `help` command to get a list of commands available.

### Dependencies

- [AWK](https://www.gnu.org/software/gawk/manual/gawk.html)
- [jq](https://jqlang.github.io/jq/)
