import { useCallback, useEffect, useMemo, useState } from 'react';
import { Edit, Package, Plus, PlusCircle, Save, Trash2 } from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, DataTable, Input, Modal, Select } from '../components/ui';

const emptyProducto = {
    codigo: '',
    codigo_barras: '',
    nombre: '',
    descripcion_ticket: '',
    categoria_id: '',
    sub_categoria_id: '',
    marca_id: '',
    sub_marca_id: '',
    unidad_medida_id: '',
    factor_compra_base: '1',
    stock_minimo: '',
    stock_maximo: '',
    activo: true,
};

const nuevaDerivada = () => ({
    unidad_base_id: '',
    factor_conversion: '1',
    precio_compra: '',
    margen: '',
    precio_venta: '',
    producto_complementario_id: '',
    cantidad_complementaria: '',
    codigo_barras: '',
});

export default function Productos() {
    const toast = useToast();
    const [productos, setProductos] = useState([]);
    const [categorias, setCategorias] = useState([]);
    const [marcas, setMarcas] = useState([]);
    const [subMarcas, setSubMarcas] = useState([]);
    const [unidades, setUnidades] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [form, setForm] = useState(emptyProducto);
    const [derivadas, setDerivadas] = useState([nuevaDerivada()]);
    const [errors, setErrors] = useState({});
    const [saving, setSaving] = useState(false);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

    const [quick, setQuick] = useState(null); // { tipo }

    const [filterEstado, setFilterEstado] = useState('');
    const [activeFilters, setActiveFilters] = useState({});

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const [prodsRes, catRes, marRes, subRes, uniRes] = await Promise.all([
                api.get('/productos'),
                api.get('/categorias'),
                api.get('/marcas'),
                api.get('/sub-marcas'),
                api.get('/unidades-medida'),
            ]);
            setProductos(asList(prodsRes));
            setCategorias(asList(catRes));
            setMarcas(asList(marRes));
            setSubMarcas(asList(subRes));
            setUnidades(asList(uniRes));
        } catch {
            setError('No se pudieron cargar los productos.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    // ---- Catálogos derivados ----
    const categoriasRaiz = categorias.filter((c) => !c.categoria_padre_id);
    const subCategoriasDe = (padreId) =>
        categorias.filter((c) => String(c.categoria_padre_id ?? '') === String(padreId));
    const subMarcasDe = (marcaId) =>
        subMarcas.filter((s) => String(s.marca_id) === String(marcaId));

    const unidadOptions = unidades.map((u) => ({
        value: String(u.id),
        label: u.abreviatura ? `${u.nombre} (${u.abreviatura})` : u.nombre,
    }));
    const unidadFactor = (id) =>
        Number(unidades.find((u) => String(u.id) === String(id))?.factor_base) || 1;
    const unidadNombre = (id) => unidades.find((u) => String(u.id) === String(id))?.nombre ?? '';
    const unidadAbrev = (id) => unidades.find((u) => String(u.id) === String(id))?.abreviatura ?? '';

    // ---- Abrir / editar ----
    const openCreate = () => {
        setEditing(null);
        setForm(emptyProducto);
        setDerivadas([nuevaDerivada()]);
        setErrors({});
        setModalOpen(true);
    };

    const openEdit = (prod) => {
        const relId = (direct, rel) =>
            prod[direct] ? String(prod[direct]) : prod[rel]?.id ? String(prod[rel].id) : '';
        setEditing(prod);
        setForm({
            codigo: prod.codigo ?? '',
            codigo_barras: prod.codigo_barras ?? '',
            nombre: prod.nombre ?? '',
            descripcion_ticket: prod.descripcion_ticket ?? '',
            categoria_id: relId('categoria_id', 'categoria'),
            sub_categoria_id: relId('sub_categoria_id', 'sub_categoria'),
            marca_id: relId('marca_id', 'marca'),
            sub_marca_id: relId('sub_marca_id', 'sub_marca'),
            unidad_medida_id: relId('unidad_medida_id', 'unidad_medida'),
            factor_compra_base: prod.factor_compra_base ?? '1',
            stock_minimo: prod.stock_minimo ?? '',
            stock_maximo: prod.stock_maximo ?? '',
            activo: prod.activo !== false,
        });
        const pres = Array.isArray(prod.presentaciones) ? prod.presentaciones : [];
        setDerivadas(
            pres.length
                ? pres.map((p) => ({
                      unidad_base_id: p.unidad_base?.id ? String(p.unidad_base.id) : '',
                      factor_conversion: String(p.factor_conversion ?? '1'),
                      precio_compra: p.precio_compra != null ? String(p.precio_compra) : '',
                      margen: p.margen != null ? String(p.margen) : '',
                      precio_venta: p.precio_venta != null ? String(p.precio_venta) : '',
                      producto_complementario_id: p.producto_complementario_id
                          ? String(p.producto_complementario_id)
                          : '',
                      cantidad_complementaria:
                          p.cantidad_complementaria != null ? String(p.cantidad_complementaria) : '',
                      codigo_barras: p.codigo_barras ?? '',
                      _nombre: p.nombre ?? '',
                  }))
                : [nuevaDerivada()],
        );
        setErrors({});
        setModalOpen(true);
    };

    const setField = (field) => (e) => {
        const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
        setForm((prev) => ({ ...prev, [field]: value }));
        setErrors((prev) => ({ ...prev, [field]: undefined }));
    };

    // ---- Filas de unidades derivadas ----
    const addDerivada = () => setDerivadas((prev) => [...prev, nuevaDerivada()]);
    const removeDerivada = (index) =>
        setDerivadas((prev) => (prev.length === 1 ? prev : prev.filter((_, i) => i !== index)));

    const setDerivadaField = (index, field, value) =>
        setDerivadas((prev) => prev.map((d, i) => (i === index ? { ...d, [field]: value } : d)));

    // Al elegir la unidad de la fila, el factor a la unidad base se calcula solo (editable).
    const setDerivadaUnidad = (index, unidadId) => {
        const base = unidadFactor(form.unidad_medida_id);
        const factor = base > 0 ? +(unidadFactor(unidadId) / base).toFixed(3) : unidadFactor(unidadId);
        setDerivadas((prev) =>
            prev.map((d, i) =>
                i === index ? { ...d, unidad_base_id: unidadId, factor_conversion: String(factor) } : d,
            ),
        );
    };

    // Precio venta = precio compra * (1 + margen/100).
    const recomputeVenta = (index, patch) => {
        setDerivadas((prev) =>
            prev.map((d, i) => {
                if (i !== index) return d;
                const next = { ...d, ...patch };
                const compra = Number(next.precio_compra);
                const margen = Number(next.margen);
                if (!Number.isNaN(compra) && next.precio_compra !== '' && next.margen !== '' && !Number.isNaN(margen)) {
                    next.precio_venta = (compra * (1 + margen / 100)).toFixed(2);
                }
                return next;
            }),
        );
    };

    const productoOptions = useMemo(
        () => [
            { value: '', label: 'Ninguno' },
            ...productos
                .filter((p) => !editing || String(p.id) !== String(editing.id))
                .map((p) => ({ value: String(p.id), label: p.nombre })),
        ],
        [productos, editing],
    );

    // ---- Guardar ----
    const validate = () => {
        const next = {};
        if (!form.codigo.trim()) next.codigo = 'Ingrese el código';
        if (!form.nombre.trim()) next.nombre = 'Ingrese el nombre';
        if (!form.unidad_medida_id) next.unidad_medida_id = 'Seleccione la unidad de medida';
        if (derivadas.length === 0) next.derivadas = 'Agregue al menos una unidad derivada';
        derivadas.forEach((d, i) => {
            if (!d.factor_conversion || Number(d.factor_conversion) <= 0) {
                next[`der.${i}.factor`] = 'Factor > 0';
            }
        });
        setErrors(next);
        return Object.keys(next).length === 0;
    };

    const buildPresentaciones = () =>
        derivadas.map((d, i) => {
            const nombre =
                (d._nombre && d._nombre.trim()) ||
                unidadNombre(d.unidad_base_id) ||
                `Presentación ${i + 1}`;
            const p = {
                nombre,
                factor_conversion: Number(d.factor_conversion),
                precio_compra: d.precio_compra === '' ? 0 : Number(d.precio_compra),
                margen: d.margen === '' ? 0 : Number(d.margen),
                precio_venta: d.precio_venta === '' ? 0 : Number(d.precio_venta),
                cantidad_complementaria:
                    d.cantidad_complementaria === '' ? 0 : Number(d.cantidad_complementaria),
            };
            if (d.unidad_base_id) p.unidad_base_id = d.unidad_base_id;
            if (d.producto_complementario_id) p.producto_complementario_id = d.producto_complementario_id;
            if (d.codigo_barras && d.codigo_barras.trim()) p.codigo_barras = d.codigo_barras.trim();
            return p;
        });

    const handleSave = async () => {
        if (!validate()) return;
        setSaving(true);
        setErrors({});

        const num = (v) => (v === '' || v == null ? undefined : Number(v));
        const str = (v) => (v && String(v).trim() ? String(v).trim() : undefined);

        const payload = {
            codigo: form.codigo.trim(),
            nombre: form.nombre.trim(),
            unidad_medida_id: form.unidad_medida_id,
            unidad_base_id: form.unidad_medida_id,
            activo: form.activo,
            codigo_barras: str(form.codigo_barras),
            descripcion_ticket: str(form.descripcion_ticket),
            categoria_id: form.categoria_id || undefined,
            sub_categoria_id: form.sub_categoria_id || undefined,
            marca_id: form.marca_id || undefined,
            sub_marca_id: form.sub_marca_id || undefined,
            factor_compra_base: num(form.factor_compra_base),
            stock_minimo: num(form.stock_minimo),
            stock_maximo: num(form.stock_maximo),
            presentaciones: buildPresentaciones(),
        };

        try {
            if (editing) {
                await api.put(`/productos/${editing.id}`, payload);
                toast.success('Producto actualizado correctamente.');
            } else {
                await api.post('/productos', payload);
                toast.success('Producto creado correctamente.');
            }
            setModalOpen(false);
            await load();
        } catch (err) {
            if (err.response?.status === 422) {
                const validation = err.response.data?.errors ?? {};
                setErrors(Object.fromEntries(Object.entries(validation).map(([k, v]) => [k, v[0]])));
                toast.error('Verifique los datos del producto.');
            } else {
                toast.error('No se pudo guardar el producto.');
            }
        } finally {
            setSaving(false);
        }
    };

    const handleDelete = async () => {
        setDeleting(true);
        try {
            await api.delete(`/productos/${deleteTarget.id}`);
            toast.success('Producto eliminado.');
            setDeleteTarget(null);
            await load();
        } catch {
            toast.error('No se pudo eliminar el producto.');
        } finally {
            setDeleting(false);
        }
    };

    // ---- Creación rápida de catálogos ----
    const handleQuickCreated = async (tipo, nuevo) => {
        await load();
        if (tipo === 'marca') setForm((p) => ({ ...p, marca_id: String(nuevo.id), sub_marca_id: '' }));
        if (tipo === 'submarca') setForm((p) => ({ ...p, sub_marca_id: String(nuevo.id) }));
        if (tipo === 'categoria')
            setForm((p) => ({ ...p, categoria_id: String(nuevo.id), sub_categoria_id: '' }));
        if (tipo === 'subcategoria') setForm((p) => ({ ...p, sub_categoria_id: String(nuevo.id) }));
        // Unidad: no autoselecciona base; el usuario decide dónde usarla.
    };

    // ---- Tabla lista ----
    const relName = (row, key) => {
        const r = row[key];
        return r && typeof r === 'object' ? (r.nombre ?? '') : '';
    };

    const columns = [
        {
            key: 'nombre',
            label: 'Producto',
            render: (row) => (
                <span className="flex items-center gap-2">
                    <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary-100 text-primary-700">
                        <Package className="h-4 w-4" />
                    </span>
                    <span>
                        <span className="block font-medium text-warm-900">{row.nombre}</span>
                        <span className="block text-xs text-gray-500">{row.codigo}</span>
                    </span>
                </span>
            ),
        },
        {
            key: 'categoria',
            label: 'Categoría',
            render: (row) => {
                const cat = relName(row, 'categoria');
                const sub = relName(row, 'sub_categoria');
                if (!cat) return <span className="text-gray-400">—</span>;
                return (
                    <span className="text-sm">
                        {cat}
                        {sub && <span className="text-gray-400"> · {sub}</span>}
                    </span>
                );
            },
        },
        {
            key: 'marca',
            label: 'Marca',
            render: (row) => relName(row, 'marca') || <span className="text-gray-400">—</span>,
        },
        {
            key: 'unidad_medida',
            label: 'Unidad',
            render: (row) => {
                const u = row.unidad_medida;
                return u && typeof u === 'object' ? (
                    <Badge variant="blue">{u.abreviatura ?? u.nombre}</Badge>
                ) : (
                    <span className="text-gray-400">—</span>
                );
            },
        },
        {
            key: 'presentaciones',
            label: 'Unid. derivadas',
            align: 'right',
            render: (row) =>
                Array.isArray(row.presentaciones) ? (
                    <Badge variant="gray">{row.presentaciones.length}</Badge>
                ) : (
                    <span className="text-gray-400">—</span>
                ),
        },
        {
            key: 'activo',
            label: 'Estado',
            render: (row) =>
                row.activo ? <Badge variant="green">Activo</Badge> : <Badge variant="red">Inactivo</Badge>,
        },
        {
            type: 'actions',
            key: 'actions',
            label: 'Acciones',
            actions: (row) => (
                <>
                    <button
                        aria-label="Editar"
                        onClick={() => openEdit(row)}
                        className="rounded-md p-1.5 text-primary-600 transition hover:bg-primary-50 hover:text-primary-700"
                    >
                        <Edit className="h-4 w-4" />
                    </button>
                    <button
                        aria-label="Eliminar"
                        onClick={() => setDeleteTarget(row)}
                        className="rounded-md p-1.5 text-red-600 transition hover:bg-red-50 hover:text-red-700"
                    >
                        <Trash2 className="h-4 w-4" />
                    </button>
                </>
            ),
        },
    ];

    const applyFilters = () => setActiveFilters(filterEstado ? { estado: filterEstado } : {});
    const clearFilters = () => {
        setFilterEstado('');
        setActiveFilters({});
    };
    const filteredProductos = productos.filter((p) => {
        if (activeFilters.estado === 'activos') return p.activo !== false;
        if (activeFilters.estado === 'inactivos') return p.activo === false;
        return true;
    });
    const filterCount = Object.keys(activeFilters).length;

    const productFilters = (
        <div className="flex flex-wrap items-end gap-3">
            <Select
                label="Estado"
                value={filterEstado}
                onChange={(e) => setFilterEstado(e.target.value)}
                options={[
                    { value: '', label: 'Todos' },
                    { value: 'activos', label: 'Solo activos' },
                    { value: 'inactivos', label: 'Solo inactivos' },
                ]}
                className="w-44"
            />
            <Button variant="primary" size="sm" onClick={applyFilters}>
                Aplicar
            </Button>
            {filterCount > 0 && (
                <Button variant="ghost" size="sm" onClick={clearFilters}>
                    Limpiar
                </Button>
            )}
        </div>
    );

    const baseAbrev = unidadAbrev(form.unidad_medida_id) || 'base';

    return (
        <Layout>
            <PageHeader
                title="Productos"
                description="Administra el catálogo, sus unidades derivadas y precios"
                actions={<CreateButton onClick={openCreate}>Crear producto</CreateButton>}
            />

            {error && (
                <Alert variant="error" className="mb-4">
                    {error}
                </Alert>
            )}

            <DataTable
                columns={columns}
                rows={filteredProductos}
                loading={loading}
                searchPlaceholder="Buscar productos..."
                filterable
                filters={productFilters}
                filterCount={filterCount}
            />

            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Editar producto' : 'Agregar producto'}
                description={editing ? `Modifica "${editing.nombre}"` : 'Completa los datos del producto'}
                size="3xl"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)}>
                            Cancelar
                        </Button>
                        <Button loading={saving} onClick={handleSave}>
                            <Save className="h-4 w-4" />
                            {editing ? 'Guardar cambios' : 'Crear producto'}
                        </Button>
                    </>
                }
            >
                <div className="space-y-6">
                    {/* Identificación */}
                    <section>
                        <h3 className="mb-2 text-xs font-semibold uppercase tracking-wider text-gray-500">
                            Identificación
                        </h3>
                        <div className="grid gap-4 sm:grid-cols-3">
                            <Input
                                label="Código / SKU"
                                value={form.codigo}
                                onChange={setField('codigo')}
                                error={errors.codigo}
                            />
                            <Input
                                label="Código de barra"
                                value={form.codigo_barras}
                                onChange={setField('codigo_barras')}
                                error={errors.codigo_barras}
                            />
                            <label className="flex items-end gap-2 pb-2 text-sm text-gray-700">
                                <input
                                    type="checkbox"
                                    checked={form.activo}
                                    onChange={setField('activo')}
                                    className="h-4 w-4 rounded border-gray-300 accent-primary-600"
                                />
                                Producto activo
                            </label>
                            <Input
                                label="Producto"
                                value={form.nombre}
                                onChange={setField('nombre')}
                                error={errors.nombre}
                                className="sm:col-span-2"
                            />
                            <Input
                                label="Descripción ticket"
                                value={form.descripcion_ticket}
                                onChange={setField('descripcion_ticket')}
                            />
                        </div>
                    </section>

                    {/* Clasificación con creación rápida */}
                    <section>
                        <h3 className="mb-2 text-xs font-semibold uppercase tracking-wider text-gray-500">
                            Clasificación
                        </h3>
                        <div className="grid gap-4 sm:grid-cols-2">
                            <FieldWithAdd onAdd={() => setQuick({ tipo: 'categoria' })}>
                                <Select
                                    label="Categoría"
                                    value={form.categoria_id}
                                    onChange={(e) =>
                                        setForm((p) => ({
                                            ...p,
                                            categoria_id: e.target.value,
                                            sub_categoria_id: '',
                                        }))
                                    }
                                    options={[
                                        { value: '', label: 'Seleccionar categoría' },
                                        ...categoriasRaiz.map((c) => ({
                                            value: String(c.id),
                                            label: c.nombre,
                                        })),
                                    ]}
                                />
                            </FieldWithAdd>
                            <FieldWithAdd
                                onAdd={() =>
                                    form.categoria_id
                                        ? setQuick({ tipo: 'subcategoria' })
                                        : toast.error('Elige una categoría primero.')
                                }
                            >
                                <Select
                                    label="Subcategoría"
                                    value={form.sub_categoria_id}
                                    onChange={setField('sub_categoria_id')}
                                    options={[
                                        { value: '', label: 'Seleccionar subcategoría' },
                                        ...subCategoriasDe(form.categoria_id).map((c) => ({
                                            value: String(c.id),
                                            label: c.nombre,
                                        })),
                                    ]}
                                />
                            </FieldWithAdd>
                            <FieldWithAdd onAdd={() => setQuick({ tipo: 'marca' })}>
                                <Select
                                    label="Marca"
                                    value={form.marca_id}
                                    onChange={(e) =>
                                        setForm((p) => ({
                                            ...p,
                                            marca_id: e.target.value,
                                            sub_marca_id: '',
                                        }))
                                    }
                                    options={[
                                        { value: '', label: 'Seleccionar marca' },
                                        ...marcas.map((m) => ({ value: String(m.id), label: m.nombre })),
                                    ]}
                                />
                            </FieldWithAdd>
                            <FieldWithAdd
                                onAdd={() =>
                                    form.marca_id
                                        ? setQuick({ tipo: 'submarca' })
                                        : toast.error('Elige una marca primero.')
                                }
                            >
                                <Select
                                    label="Submarca"
                                    value={form.sub_marca_id}
                                    onChange={setField('sub_marca_id')}
                                    options={[
                                        { value: '', label: 'Seleccionar submarca' },
                                        ...subMarcasDe(form.marca_id).map((s) => ({
                                            value: String(s.id),
                                            label: s.nombre,
                                        })),
                                    ]}
                                />
                            </FieldWithAdd>
                        </div>
                    </section>

                    {/* Unidad base y stock */}
                    <section>
                        <h3 className="mb-2 text-xs font-semibold uppercase tracking-wider text-gray-500">
                            Unidad base e inventario
                        </h3>
                        <div className="grid gap-4 sm:grid-cols-4">
                            <FieldWithAdd onAdd={() => setQuick({ tipo: 'unidad' })}>
                                <Select
                                    label="U. de medida (base)"
                                    value={form.unidad_medida_id}
                                    onChange={setField('unidad_medida_id')}
                                    options={[{ value: '', label: 'Unidad base' }, ...unidadOptions]}
                                    error={errors.unidad_medida_id}
                                />
                            </FieldWithAdd>
                            <Input
                                label="Unid. contenidas"
                                type="number"
                                step="any"
                                min="0.001"
                                value={form.factor_compra_base}
                                onChange={setField('factor_compra_base')}
                            />
                            <Input
                                label="Stock mín."
                                type="number"
                                step="any"
                                min="0"
                                value={form.stock_minimo}
                                onChange={setField('stock_minimo')}
                            />
                            <Input
                                label="Stock máx."
                                type="number"
                                step="any"
                                min="0"
                                value={form.stock_maximo}
                                onChange={setField('stock_maximo')}
                            />
                        </div>
                    </section>

                    {/* Detalle de precios / unidades derivadas */}
                    <section>
                        <div className="mb-2 flex items-center justify-between">
                            <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-500">
                                Detalle de precios — unidades derivadas
                            </h3>
                            <Button variant="secondary" size="sm" onClick={addDerivada}>
                                <Plus className="h-4 w-4" />
                                Agregar unidad derivada
                            </Button>
                        </div>
                        {errors.derivadas && (
                            <Alert variant="warning" className="mb-2">
                                {errors.derivadas}
                            </Alert>
                        )}
                        <div className="overflow-x-auto rounded-lg border border-edge">
                            <table className="w-full min-w-[860px] text-sm">
                                <thead>
                                    <tr className="bg-primary-600 text-left text-xs text-white">
                                        <th className="px-2 py-2 font-medium">Formato de venta</th>
                                        <th className="px-2 py-2 font-medium">Factor ({baseAbrev})</th>
                                        <th className="px-2 py-2 font-medium">P. compra</th>
                                        <th className="px-2 py-2 font-medium">% venta</th>
                                        <th className="px-2 py-2 font-medium">P. venta</th>
                                        <th className="px-2 py-2 font-medium">Complementario</th>
                                        <th className="px-2 py-2 font-medium">Cant.</th>
                                        <th className="w-10 px-2 py-2" />
                                    </tr>
                                </thead>
                                <tbody>
                                    {derivadas.map((d, i) => (
                                        <tr key={i} className="border-t border-edge">
                                            <td className="px-2 py-1.5">
                                                <select
                                                    className="h-8 w-full rounded-md border border-gray-300 bg-white px-2 text-sm"
                                                    value={d.unidad_base_id}
                                                    onChange={(e) => setDerivadaUnidad(i, e.target.value)}
                                                >
                                                    <option value="">Elegir unidad…</option>
                                                    {unidadOptions.map((o) => (
                                                        <option key={o.value} value={o.value}>
                                                            {o.label}
                                                        </option>
                                                    ))}
                                                </select>
                                            </td>
                                            <td className="px-2 py-1.5">
                                                <input
                                                    type="number"
                                                    step="0.001"
                                                    min="0.001"
                                                    className={`h-8 w-24 rounded-md border px-2 text-sm ${
                                                        errors[`der.${i}.factor`]
                                                            ? 'border-red-400'
                                                            : 'border-gray-300'
                                                    }`}
                                                    value={d.factor_conversion}
                                                    onChange={(e) =>
                                                        setDerivadaField(i, 'factor_conversion', e.target.value)
                                                    }
                                                />
                                            </td>
                                            <td className="px-2 py-1.5">
                                                <input
                                                    type="number"
                                                    step="any"
                                                    min="0"
                                                    className="h-8 w-24 rounded-md border border-gray-300 px-2 text-sm"
                                                    value={d.precio_compra}
                                                    onChange={(e) =>
                                                        recomputeVenta(i, { precio_compra: e.target.value })
                                                    }
                                                />
                                            </td>
                                            <td className="px-2 py-1.5">
                                                <input
                                                    type="number"
                                                    step="any"
                                                    className="h-8 w-20 rounded-md border border-gray-300 px-2 text-sm"
                                                    value={d.margen}
                                                    onChange={(e) => recomputeVenta(i, { margen: e.target.value })}
                                                />
                                            </td>
                                            <td className="px-2 py-1.5">
                                                <input
                                                    type="number"
                                                    step="any"
                                                    min="0"
                                                    className="h-8 w-24 rounded-md border border-gray-300 bg-emerald-50 px-2 text-sm font-medium"
                                                    value={d.precio_venta}
                                                    onChange={(e) =>
                                                        setDerivadaField(i, 'precio_venta', e.target.value)
                                                    }
                                                />
                                            </td>
                                            <td className="px-2 py-1.5">
                                                <select
                                                    className="h-8 w-40 rounded-md border border-gray-300 bg-white px-2 text-sm"
                                                    value={d.producto_complementario_id}
                                                    onChange={(e) =>
                                                        setDerivadaField(
                                                            i,
                                                            'producto_complementario_id',
                                                            e.target.value,
                                                        )
                                                    }
                                                >
                                                    {productoOptions.map((o) => (
                                                        <option key={o.value} value={o.value}>
                                                            {o.label}
                                                        </option>
                                                    ))}
                                                </select>
                                            </td>
                                            <td className="px-2 py-1.5">
                                                <input
                                                    type="number"
                                                    step="any"
                                                    min="0"
                                                    className="h-8 w-20 rounded-md border border-gray-300 px-2 text-sm"
                                                    value={d.cantidad_complementaria}
                                                    onChange={(e) =>
                                                        setDerivadaField(
                                                            i,
                                                            'cantidad_complementaria',
                                                            e.target.value,
                                                        )
                                                    }
                                                />
                                            </td>
                                            <td className="px-2 py-1.5 text-center">
                                                <button
                                                    type="button"
                                                    aria-label="Quitar"
                                                    disabled={derivadas.length === 1}
                                                    onClick={() => removeDerivada(i)}
                                                    className="rounded p-1 text-red-600 transition hover:bg-red-50 disabled:opacity-30"
                                                >
                                                    <Trash2 className="h-4 w-4" />
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                        <p className="mt-2 text-xs text-gray-400">
                            El <strong>factor</strong> se calcula al elegir la unidad (en {baseAbrev}) y es
                            editable — para empaques variables (ej. saco de arroz = 49, de azúcar = 50). El
                            precio de venta = compra × (1 + % venta), editable.
                        </p>
                    </section>
                </div>
            </Modal>

            <QuickCreateModal
                quick={quick}
                onClose={() => setQuick(null)}
                onCreated={handleQuickCreated}
                marcaId={form.marca_id}
                categoriaId={form.categoria_id}
                marcas={marcas}
                categoriasRaiz={categoriasRaiz}
            />

            <Modal
                open={Boolean(deleteTarget)}
                onClose={() => setDeleteTarget(null)}
                title="Eliminar producto"
                description={`¿Seguro que deseas eliminar "${deleteTarget?.nombre}"?`}
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setDeleteTarget(null)}>
                            Cancelar
                        </Button>
                        <Button variant="danger" loading={deleting} onClick={handleDelete}>
                            Eliminar
                        </Button>
                    </>
                }
            >
                <Alert variant="warning">Se eliminarán también sus unidades derivadas.</Alert>
            </Modal>
        </Layout>
    );
}

// Envuelve un Select con un botón "+" a la derecha para creación rápida.
function FieldWithAdd({ children, onAdd }) {
    return (
        <div className="flex items-end gap-2">
            <div className="flex-1">{children}</div>
            <button
                type="button"
                onClick={onAdd}
                title="Crear nuevo"
                className="mb-0.5 rounded-md p-1.5 text-emerald-600 transition hover:bg-emerald-50"
            >
                <PlusCircle className="h-5 w-5" />
            </button>
        </div>
    );
}

// Mini-modal de creación rápida de catálogos.
function QuickCreateModal({ quick, onClose, onCreated, marcaId, categoriaId, marcas, categoriasRaiz }) {
    const toast = useToast();
    const [values, setValues] = useState({});
    const [saving, setSaving] = useState(false);

    const cfg = useMemo(() => {
        switch (quick?.tipo) {
            case 'marca':
                return {
                    title: 'Nueva marca',
                    endpoint: '/marcas',
                    build: (v) => ({ nombre: v.nombre, activo: true }),
                    fields: [{ key: 'nombre', label: 'Nombre de marca', required: true }],
                };
            case 'submarca':
                return {
                    title: 'Nueva submarca',
                    endpoint: '/sub-marcas',
                    build: (v) => ({ marca_id: marcaId, nombre: v.nombre, activo: true }),
                    fields: [{ key: 'nombre', label: 'Nombre de submarca', required: true }],
                };
            case 'categoria':
                return {
                    title: 'Nueva categoría',
                    endpoint: '/categorias',
                    build: (v) => ({ nombre: v.nombre, nivel: 1, activo: true }),
                    fields: [{ key: 'nombre', label: 'Nombre de categoría', required: true }],
                };
            case 'subcategoria':
                return {
                    title: 'Nueva subcategoría',
                    endpoint: '/categorias',
                    build: (v) => ({
                        nombre: v.nombre,
                        categoria_padre_id: categoriaId,
                        nivel: 2,
                        activo: true,
                    }),
                    fields: [{ key: 'nombre', label: 'Nombre de subcategoría', required: true }],
                };
            case 'unidad':
                return {
                    title: 'Nueva unidad de medida',
                    endpoint: '/unidades-medida',
                    build: (v) => ({
                        nombre: v.nombre,
                        abreviatura: v.abreviatura,
                        factor_base: v.factor_base === '' || v.factor_base == null ? 1 : Number(v.factor_base),
                    }),
                    fields: [
                        { key: 'nombre', label: 'Nombre (ej: SACO)', required: true },
                        { key: 'abreviatura', label: 'Abreviatura (ej: sc)', required: true },
                        {
                            key: 'factor_base',
                            label: 'Equivale a (en su unidad mínima)',
                            type: 'number',
                        },
                    ],
                };
            default:
                return null;
        }
    }, [quick, marcaId, categoriaId]);

    useEffect(() => {
        setValues({});
    }, [quick]);

    if (!quick || !cfg) return null;

    const canSave = cfg.fields.every((f) => !f.required || (values[f.key] ?? '').toString().trim());

    const submit = async () => {
        setSaving(true);
        try {
            const res = await api.post(cfg.endpoint, cfg.build(values));
            const nuevo = res.data?.data ?? res.data;
            toast.success(`${cfg.title.replace('Nueva ', '').replace('Nuevo ', '')} creada.`);
            await onCreated(quick.tipo, nuevo);
            onClose();
        } catch {
            toast.error('No se pudo crear. Verifica los datos.');
        } finally {
            setSaving(false);
        }
    };

    return (
        <Modal
            open
            onClose={onClose}
            title={cfg.title}
            size="sm"
            footer={
                <>
                    <Button variant="secondary" onClick={onClose}>
                        Cancelar
                    </Button>
                    <Button loading={saving} disabled={!canSave} onClick={submit}>
                        Guardar
                    </Button>
                </>
            }
        >
            <div className="space-y-3">
                {quick.tipo === 'submarca' && (
                    <p className="text-xs text-gray-500">
                        Marca: <strong>{marcas.find((m) => String(m.id) === String(marcaId))?.nombre}</strong>
                    </p>
                )}
                {quick.tipo === 'subcategoria' && (
                    <p className="text-xs text-gray-500">
                        Categoría:{' '}
                        <strong>
                            {categoriasRaiz.find((c) => String(c.id) === String(categoriaId))?.nombre}
                        </strong>
                    </p>
                )}
                {cfg.fields.map((f) => (
                    <Input
                        key={f.key}
                        label={f.label}
                        type={f.type ?? 'text'}
                        value={values[f.key] ?? ''}
                        onChange={(e) => setValues((prev) => ({ ...prev, [f.key]: e.target.value }))}
                    />
                ))}
            </div>
        </Modal>
    );
}
