from models import get_hosts
import yaml
import sys

hostnames = sys.argv[1:]

hosts = get_hosts(hostnames)

if len(hosts):
    data = {
        "monitoring": {
            "hosts": [h.model_dump(exclude_none=True) for h in hosts]
        }
    }

    print(yaml.safe_dump(data, sort_keys=False, allow_unicode=True))
