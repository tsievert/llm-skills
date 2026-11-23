# Sketch: check signatures in the live docs for the installed DLC version first.
import argparse
import deeplabcut

ap = argparse.ArgumentParser()
ap.add_argument("--config", required=True)
ap.add_argument("--shuffle", type=int, default=1)
a = ap.parse_args()

deeplabcut.train_network(a.config, shuffle=a.shuffle)  # add epochs/batch_size etc. per docs
deeplabcut.evaluate_network(a.config, shuffles=[a.shuffle], plotting=False)
