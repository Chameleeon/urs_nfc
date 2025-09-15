# board/terasic/de1soc_cyclone5/post-image.sh
#!/bin/bash

# Copy socfpga.rbf to the boot partition
cp ${BR2_EXTERNAL_PATH:-board/terasic/de1soc_cyclone5}/socfpga.rbf ${BINARIES_DIR}/
