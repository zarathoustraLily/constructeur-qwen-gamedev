import sys
import time

from usine.processus import executer


def test_sortie_et_code():
    res = executer([sys.executable, "-c", "import sys; print('bonjour'); sys.stderr.write('err\\n'); sys.exit(3)"])
    assert res.code == 3
    assert "bonjour" in res.sortie and "err" in res.sortie
    assert not res.expire


def test_delai_depasse_tue_le_processus():
    debut = time.monotonic()
    res = executer([sys.executable, "-c", "import time; time.sleep(30)"], delai_s=1)
    assert res.expire
    assert res.code is None
    assert time.monotonic() - debut < 15
