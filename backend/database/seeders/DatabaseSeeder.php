<?php

namespace Database\Seeders;

use App\Models\Empresa;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $superAdmin = Role::create(['name' => 'super-admin']);
        Role::create(['name' => 'admin']);
        Role::create(['name' => 'user']);

        $empresa = Empresa::create([
            'ruc' => '20123456789',
            'razon_social' => 'Brother Corp S.A.C.',
            'nombre_comercial' => 'Brother',
            'direccion' => 'Av. Principal 123',
            'telefono' => '999888777',
            'email' => 'contacto@brother.com',
        ]);

        $user = User::factory()->create([
            'name' => 'Super Admin',
            'email' => 'admin@brother.com',
            'password' => 'password',
            'empresa_id' => $empresa->id,
        ]);

        $user->assignRole($superAdmin);
    }
}
