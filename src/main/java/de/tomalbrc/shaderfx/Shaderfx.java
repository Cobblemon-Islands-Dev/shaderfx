package de.tomalbrc.shaderfx;

import de.tomalbrc.shaderfx.api.ShaderEffects;
import de.tomalbrc.shaderfx.impl.ModCommands;
import de.tomalbrc.shaderfx.impl.ModConfig;
import de.tomalbrc.shaderfx.impl.RPHandler;
import eu.pb4.polymer.resourcepack.api.PolymerResourcePackUtils;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents;
import net.fabricmc.fabric.api.networking.v1.ServerPlayConnectionEvents;
import net.kyori.adventure.platform.fabric.FabricAudiences;
import net.kyori.adventure.platform.fabric.FabricServerAudiences;
import net.minecraft.network.chat.Component;
import net.minecraft.network.protocol.game.ClientboundBundlePacket;
import net.minecraft.network.protocol.game.ClientboundSetTitleTextPacket;
import net.minecraft.network.protocol.game.ClientboundSetTitlesAnimationPacket;
import net.minecraft.resources.ResourceLocation;

import java.util.List;

public class Shaderfx implements ModInitializer {
    public static final String MODID = "shaderfx";
    public static FabricAudiences ADVENTURE;

    public static FabricAudiences adventure() {
        if (ADVENTURE == null) {
            throw new IllegalStateException("Tried to access Adventure without a running server!");
        }
        return ADVENTURE;
    }

    @Override
    public void onInitialize() {
        if (ModConfig.getInstance().addAssets) RPHandler.enableAssets();
        if (ModConfig.getInstance().enableAnimatedEmojiConversion) RPHandler.enableAnimojiConversion();
        if (ModConfig.getInstance().markAsRequired) PolymerResourcePackUtils.markAsRequired();

        ShaderEffects.addImport(ResourceLocation.withDefaultNamespace("shaderfx_utils.glsl"));
        ShaderEffects.addImport(ResourceLocation.withDefaultNamespace("spikes.glsl"));
        ShaderEffects.addImport(ResourceLocation.withDefaultNamespace("endfx.glsl"));
        ShaderEffects.addImport(ResourceLocation.withDefaultNamespace("realmfx.glsl"));

        ServerLifecycleEvents.SERVER_STARTING.register(server -> ADVENTURE = FabricServerAudiences.of(server));

        var joinEffect = ModConfig.getInstance().joinEffect;
        if (joinEffect != null && joinEffect.enabled()) {
            ServerPlayConnectionEvents.JOIN.register((serverGamePacketListener, packetSender, server) -> {
                var p1 = new ClientboundSetTitlesAnimationPacket(0, joinEffect.stay(), joinEffect.fadeOut());

                Component fx;
                if (joinEffect.type().equalsIgnoreCase("transition")) fx = ShaderEffects.transitionComponent(joinEffect.effect(), joinEffect.color());
                else fx = ShaderEffects.effectComponent(joinEffect.effect(), joinEffect.color());

                var p2 = new ClientboundSetTitleTextPacket(fx);
                serverGamePacketListener.send(new ClientboundBundlePacket(List.of(p1, p2)));
            });
        }

        ModCommands.register();
    }
}
