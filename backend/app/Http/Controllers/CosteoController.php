<?php

namespace App\Http\Controllers;

use App\Models\CosteoConfig;
use Illuminate\Http\Request;

class CosteoController extends Controller
{
    public function __construct()
    {
    }

    public function index()
    {
        return response()->json(CosteoConfig::first());
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'metodo' => 'required|string|max:50',
        ]);
        $config = CosteoConfig::first();
        if ($config) {
            $config->update($data);
        } else {
            $config = CosteoConfig::create($data);
        }
        return response()->json($config);
    }
}
