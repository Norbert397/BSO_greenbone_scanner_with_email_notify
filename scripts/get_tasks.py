import sys

from gvm.connections import UnixSocketConnection
from gvm.errors import GvmError
from gvm.protocols.gmp import Gmp
from gvm.transforms import EtreeCheckCommandTransform

path = '/run/gvmd/gvmd.sock'
connection = UnixSocketConnection(path=path)
transform = EtreeCheckCommandTransform()

username = 'admin'
password = 'admin'

try:
    tasks = []

    with Gmp(connection=connection, transform=transform) as gmp:
        gmp.authenticate(username, password)

        tasks = gmp.get_tasks(filter_string='name~weekly')

        for task in tasks.xpath('task'):
            print(task.find('name').text)

except GvmError as e:
    print('An error occurred', e, file=sys.stderr)
