#
# Copyright (C) 2025 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Enable updating of APEXes
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

# A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl \
    android.hardware.boot@1.2-impl.recovery \
    android.hardware.boot@1.2-service

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# API levels
BOARD_API_LEVEL := 202504
PRODUCT_SHIPPING_API_LEVEL := 36

# fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

# Health
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# Overlays
PRODUCT_ENFORCE_RRO_TARGETS := *

# Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Product characteristics
PRODUCT_CHARACTERISTICS := nosdcard

# Rootdir
PRODUCT_PACKAGES += \
    dump_dwc3.sh \
    dump_gsc.sh \
    dump_pcie.sh \
    dump_thermal.sh \
    dump_touch.sh \
    dump_trusty.sh \
    predump_gti0.sh \
    disable_contaminant_detection.sh \
    init.h2omg.sh \
    init_rdbl.sh \
    init.radio.sh \
    insmod.sh \
    pixel-experiments-recovery.sh \
    predump_touch.sh \
    storage_init.sh \
    storage_intelligence.sh \

PRODUCT_PACKAGES += \
    fstab.zram.50p-1g \
    init.efs.rc \
    init.laguna.rc \
    init.laguna.usb.rc \
    init.mustang.rc \
    init.persist.rc \

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.zram.50p-1g:$(TARGET_VENDOR_RAMDISK_OUT)/first_stage_ramdisk/fstab.zram.50p-1g

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Inherit the proprietary files
$(call inherit-product, vendor/google/generic/generic-vendor.mk)
