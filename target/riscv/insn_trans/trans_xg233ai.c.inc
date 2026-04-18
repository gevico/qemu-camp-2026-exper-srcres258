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

static bool trans_sort(DisasContext *ctx, arg_r *a)
{
    if (!ctx->cfg_ptr->ext_xg233ai) {
        return false;
    }

    TCGv addr = get_gpr(ctx, a->rs1, EXT_NONE);
    TCGv total = get_gpr(ctx, a->rs2, EXT_NONE);
    TCGv count = get_gpr(ctx, a->rd, EXT_NONE);

    gen_helper_sort(tcg_env, addr, total, count);
    return true;
}

static bool trans_crush(DisasContext *ctx, arg_r *a)
{
    if (!ctx->cfg_ptr->ext_xg233ai) {
        return false;
    }

    TCGv rd = get_gpr(ctx, a->rd, EXT_NONE);
    TCGv rs1 = get_gpr(ctx, a->rs1, EXT_NONE);
    TCGv rs2 = get_gpr(ctx, a->rs2, EXT_NONE);

    gen_helper_crush(tcg_env, rd, rs1, rs2);
    return true;
}
