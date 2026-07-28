<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CosteoConfig extends Model
{
    protected $table = 'costeo_configs';

    protected $fillable = [
        'metodo',
    ];
}
