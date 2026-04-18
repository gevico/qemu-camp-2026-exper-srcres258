static bool trans_dma(DisasContext *ctx, arg_r *a)
{
    if (!ctx->cfg_ptr->ext_xg233ai) {
        return false;
    }

    TCGv dst = get_gpr(ctx, a->rd, EXT_NONE);
    TCGv src = get_gpr(ctx, a->rs1, EXT_NONE);
    TCGv grain = get_gpr(ctx, a->rs2, EXT_NONE);

    gen_helper_dma(tcg_env, dst, src, grain);
    return true;
}
