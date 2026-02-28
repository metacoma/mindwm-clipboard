from models import get_hosts
import yaml
import sys

import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s:%(funcName)s: %(message)s",
    stream=sys.stderr,
)

logger = logging.getLogger(__name__)

hostnames = sys.argv[1:]

logger.info(hostnames)

hosts = get_hosts(hostnames)


if len(hosts):
    data = {
        "monitoring": {
            "hosts": [h.model_dump(exclude_none=True) for h in hosts]
        }
    }

    print(yaml.safe_dump(data, sort_keys=False, allow_unicode=True))
