# Yandex Auth SDK - keep all Parcelable classes and their CREATOR fields
# This is required because Auth SDK passes Parcelable objects through Intents
-keep class com.yandex.authsdk.** { *; }
-keepclassmembers class com.yandex.authsdk.** implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Yandex Flex SDK - keep all classes to prevent R8 from removing them
-keep class com.yandex.fintechsdk.adapters.flex.** { *; }
-keep class com.yandex.fintechsdk.core.divkit.impl.internal.action.openflex.** { *; }
-keep class com.yandex.flex-sdk.** { *; }
-keep class com.yandex.flex-divkit-integration.** { *; }

