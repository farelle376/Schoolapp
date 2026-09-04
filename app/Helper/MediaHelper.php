<?php

if (!function_exists('media_url')) {
    function media_url($path)
    {
        return asset('storage/' . $path);
    }
}