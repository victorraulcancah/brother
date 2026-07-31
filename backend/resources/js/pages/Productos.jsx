import { useCallback, useEffect, useState } from 'react';
import {
    ArrowLeft,
    ArrowRight,
    Edit,
    Package,
    Plus,
    Save,
    Trash2,
    X,
} from 'lucide-react';
import api, { asList } from '../lib/api';
import { useToast } from '../lib/toast';
import Layout from '../components/Layout';
import PageHeader, { CreateButton } from '../components/PageHeader';
import { Alert, Badge, Button, Card, DataTable, Input, Modal, Select, Tabs } from '../components/ui';
import { cn } from '../components/ui/cn';

const emptyProducto = {
    codigo: '',
    nombre: '',
    categoria_id: '',
    marca_id: '',
    sub_marca_id: '',
    unidad_medida_id: '',
    unidad_compra_id: '',
    unidad_base_id: '',
    factor_compra_base: '1',
    precio_base: '',
    descripcion: '',
    afecto_igv: true,
    activo: true,
};

const emptyPresentacion = {
    nombre: '',
    codigo_barras: '',
    precio_venta: '',
    factor_conversion: '1',
    unidad_base_id: '',
};

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
    const [step, setStep] = useState(0);
    const [form, setForm] = useState(emptyProducto);
    const [presentaciones, setPresentaciones] = useState([]);
    const [errors, setErrors] = useState({});
    const [saving, setSaving] = useState(false);

    const [deleteTarget, setDeleteTarget] = useState(null);
    const [deleting, setDeleting] = useState(false);

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

    const openCreate = () => {
        setEditing(null);
        setForm(emptyProducto);
        setPresentaciones([{ ...emptyPresentacion }]);
        setErrors({});
        setStep(0);
        setModalOpen(true);
    };

    const openEdit = (prod) => {
        const relId = (direct, rel) =>
            prod[direct] ? String(prod[direct]) : (prod[rel]?.id ? String(prod[rel].id) : '');
        setEditing(prod);
        setForm({
            codigo: prod.codigo ?? '',
            nombre: prod.nombre ?? '',
            categoria_id: relId('categoria_id', 'categoria'),
            marca_id: relId('marca_id', 'marca'),
            sub_marca_id: relId('sub_marca_id', 'sub_marca'),
            unidad_medida_id: relId('unidad_medida_id', 'unidad_medida'),
            unidad_compra_id: relId('unidad_compra_id', 'unidad_compra'),
            unidad_base_id: relId('unidad_base_id', 'unidad_base'),
            factor_compra_base: prod.factor_compra_base ?? '1',
            precio_base: prod.precio_base ?? '',
            descripcion: prod.descripcion ?? '',
            afecto_igv: prod.afecto_igv !== false,
            activo: prod.activo !== false,
        });
        setPresentaciones(
            (Array.isArray(prod.presentaciones) ? prod.presentaciones : []).map((p) => ({
                nombre: p.nombre ?? '',
                codigo_barras: p.codigo_barras ?? '',
                precio_venta: p.precio_venta ?? '',
                factor_conversion: p.factor_conversion ?? '1',
                unidad_base_id: p.unidad_base?.id ? String(p.unidad_base.id) : '',
            })),
        );
        setErrors({});
        setStep(0);
        setModalOpen(true);
    };

    const setField = (field) => (e) => {
        const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
        setForm((prev) => ({ ...prev, [field]: value }));
        setErrors((prev) => ({ ...prev, [field]: undefined }));
    };

    const setPresentacionField = (index, field) => (e) => {
        const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
        setPresentaciones((prev) =>
            prev.map((p, i) => (i === index ? { ...p, [field]: value } : p)),
        );
        setErrors((prev) => ({ ...prev, [`presentaciones.${index}.${field}`]: undefined }));
    };

    const addPresentacion = () => {
        setPresentaciones((prev) => [...prev, { ...emptyPresentacion }]);
    };

    const removePresentacion = (index) => {
        setPresentaciones((prev) => prev.filter((_, i) => i !== index));
    };

    const validateStep1 = () => {
        const next = {};
        if (!form.codigo.trim()) next.codigo = 'Ingrese el código';
        if (!form.nombre.trim()) next.nombre = 'Ingrese el nombre';
        if (!form.marca_id) next.marca_id = 'Seleccione una marca';
        if (!form.unidad_medida_id) next.unidad_medida_id = 'Seleccione una unidad de medida';
        setErrors(next);
        return Object.keys(next).length === 0;
    };

    const validateStep2 = () => {
        const next = {};
        if (presentaciones.length === 0) {
            next.presentaciones = 'Agregue al menos una presentación';
        }
        presentaciones.forEach((p, index) => {
            if (!p.nombre.trim()) {
                next[`presentaciones.${index}.nombre`] = 'Requerido';
            }
            if (p.precio_venta === '' || Number.isNaN(Number(p.precio_venta))) {
                next[`presentaciones.${index}.precio_venta`] = 'Requerido';
            }
            if (!p.factor_conversion || Number(p.factor_conversion) <= 0) {
                next[`presentaciones.${index}.factor_conversion`] = 'Debe ser mayor a 0';
            }
        });
        if (form.precio_base === '' || Number.isNaN(Number(form.precio_base))) {
            next.precio_base = 'Ingrese el precio base';
        }
        setErrors(next);
        return Object.keys(next).length === 0;
    };

    const syncPresentaciones = async (productoId, lista) => {
        const { data: existentes } = await api.get(`/productos/${productoId}/presentaciones`);
        const actuales = Array.isArray(existentes) ? existentes : [];
        for (const p of actuales) {
            await api.delete(`/presentaciones/${p.id}`);
        }
        for (const p of lista) {
            const payload = {
                nombre: p.nombre.trim(),
                precio_venta: Number(p.precio_venta),
                factor_conversion: Number(p.factor_conversion),
            };
            if (p.codigo_barras.trim()) payload.codigo_barras = p.codigo_barras.trim();
            if (p.unidad_base_id) payload.unidad_base_id = p.unidad_base_id;
            await api.post(`/productos/${productoId}/presentaciones`, payload);
        }
    };

    const handleSave = async () => {
        if (step === 0) {
            if (validateStep1()) setStep(1);
            return;
        }
        if (!validateStep2()) return;

        setSaving(true);
        setErrors({});

        const payload = {
            codigo: form.codigo.trim(),
            nombre: form.nombre.trim(),
            marca_id: form.marca_id,
            unidad_medida_id: form.unidad_medida_id,
            precio_base: Number(form.precio_base),
            afecto_igv: form.afecto_igv,
            activo: form.activo,
        };
        if (form.categoria_id) payload.categoria_id = form.categoria_id;
        if (form.sub_marca_id) payload.sub_marca_id = form.sub_marca_id;
        if (form.unidad_compra_id) payload.unidad_compra_id = form.unidad_compra_id;
        if (form.unidad_base_id) payload.unidad_base_id = form.unidad_base_id;
        if (form.factor_compra_base) {
            payload.factor_compra_base = Number(form.factor_compra_base);
        }
        if (form.descripcion.trim()) payload.descripcion = form.descripcion.trim();

        try {
            const unwrap = (res) => (res.data?.data ?? res.data);
            let productoId;
            if (editing) {
                const res = await api.put(`/productos/${editing.id}`, payload);
                productoId = unwrap(res).id ?? editing.id;
                toast.success('Producto actualizado correctamente.');
            } else {
                const res = await api.post('/productos', payload);
                productoId = unwrap(res).id;
                toast.success('Producto creado correctamente.');
            }
            await syncPresentaciones(productoId, presentaciones);
            setModalOpen(false);
            await load();
        } catch (err) {
            if (err.response?.status === 422) {
                const validation = err.response.data?.errors ?? {};
                setErrors(
                    Object.fromEntries(Object.entries(validation).map(([k, v]) => [k, v[0]])),
                );
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

    const relName = (row, key) => {
        const r = row[key];
        if (r && typeof r === 'object') return r.nombre ?? '';
        return '';
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
            key: 'marca',
            label: 'Marca',
            render: (row) => relName(row, 'marca') || <span className="text-gray-400">—</span>,
        },
        {
            key: 'categoria',
            label: 'Categoría',
            render: (row) => relName(row, 'categoria') || <span className="text-gray-400">—</span>,
        },
        {
            key: 'unidad_medida',
            label: 'Unidad',
            render: (row) => {
                const u = row.unidad_medida;
                if (u && typeof u === 'object') {
                    return <Badge variant="blue">{u.abreviatura ?? u.nombre}</Badge>;
                }
                return <span className="text-gray-400">—</span>;
            },
        },
        {
            key: 'precio_base',
            label: 'Precio base',
            align: 'right',
            render: (row) => `S/ ${Number(row.precio_base ?? 0).toFixed(2)}`,
        },
        {
            key: 'presentaciones',
            label: 'Presentac.',
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
                row.activo ? (
                    <Badge variant="green">Activo</Badge>
                ) : (
                    <Badge variant="red">Inactivo</Badge>
                ),
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

    const subMarcasDeMarca = subMarcas.filter((s) => String(s.marca_id) === String(form.marca_id));

    const unidadOptions = unidades.map((u) => ({
        value: String(u.id),
        label: u.nombre,
    }));

    const applyFilters = () => {
        const next = {};
        if (filterEstado) next.estado = filterEstado;
        setActiveFilters(next);
    };

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

    return (
        <Layout>
            <PageHeader
                title="Productos"
                description="Administra el catálogo de productos y sus presentaciones"
                actions={<CreateButton onClick={openCreate}>Crear producto</CreateButton>}
            />

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

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
                title={editing ? 'Editar producto' : 'Nuevo producto'}
                description={
                    editing ? `Modifica "${editing.nombre}"` : 'Completa los datos del producto'
                }
                size="lg"
                footer={
                    <>
                        {step === 1 && (
                            <Button variant="secondary" onClick={() => setStep(0)}>
                                <ArrowLeft className="h-4 w-4" />
                                Anterior
                            </Button>
                        )}
                        {step === 0 ? (
                            <Button onClick={() => validateStep1() && setStep(1)}>
                                Siguiente
                                <ArrowRight className="h-4 w-4" />
                            </Button>
                        ) : (
                            <Button loading={saving} onClick={handleSave}>
                                <Save className="h-4 w-4" />
                                Guardar producto
                            </Button>
                        )}
                    </>
                }
            >
                <div className="mb-4">
                    <Tabs
                        items={[
                            { key: 'datos', label: 'Datos' },
                            { key: 'presentaciones', label: 'Presentaciones y precio' },
                        ]}
                        value={step === 0 ? 'datos' : 'presentaciones'}
                        onChange={(key) => {
                            if (key === 'datos') {
                                setStep(0);
                            } else if (step === 0 && !validateStep1()) {
                                return;
                            } else {
                                setStep(1);
                            }
                        }}
                    />
                </div>

                {errors.presentaciones && (
                    <Alert variant="warning" className="mb-3">
                        {errors.presentaciones}
                    </Alert>
                )}

                {step === 0 ? (
                    <div className="space-y-6">
                        <section>
                            <h3 className="mb-2 text-xs font-semibold uppercase tracking-wider text-gray-500">
                                Identificación
                            </h3>
                            <div className="grid gap-4 sm:grid-cols-2">
                                <Input
                                    label="Código / SKU"
                                    name="codigo"
                                    value={form.codigo}
                                    onChange={setField('codigo')}
                                    error={errors.codigo}
                                />
                                <Input
                                    label="Nombre del producto"
                                    name="nombre"
                                    value={form.nombre}
                                    onChange={setField('nombre')}
                                    error={errors.nombre}
                                />
                            </div>
                        </section>

                        <section>
                            <h3 className="mb-2 text-xs font-semibold uppercase tracking-wider text-gray-500">
                                Clasificación
                            </h3>
                            <div className="grid gap-4 sm:grid-cols-2">
                                <Select
                                    label="Categoría"
                                    name="categoria_id"
                                    value={form.categoria_id}
                                    onChange={setField('categoria_id')}
                                    options={[
                                        { value: '', label: 'Sin categoría' },
                                        ...categorias.map((c) => ({
                                            value: String(c.id),
                                            label: c.nombre,
                                        })),
                                    ]}
                                    error={errors.categoria_id}
                                />
                                <Select
                                    label="Marca"
                                    name="marca_id"
                                    value={form.marca_id}
                                    onChange={(e) => {
                                        setForm((prev) => ({
                                            ...prev,
                                            marca_id: e.target.value,
                                            sub_marca_id: '',
                                        }));
                                        setErrors((prev) => ({ ...prev, marca_id: undefined }));
                                    }}
                                    options={[
                                        { value: '', label: 'Seleccione...' },
                                        ...marcas.map((m) => ({
                                            value: String(m.id),
                                            label: m.nombre,
                                        })),
                                    ]}
                                    error={errors.marca_id}
                                />
                                <Select
                                    label="Sub-marca (opcional)"
                                    name="sub_marca_id"
                                    value={form.sub_marca_id}
                                    onChange={setField('sub_marca_id')}
                                    options={[
                                        { value: '', label: 'Sin sub-marca' },
                                        ...subMarcasDeMarca.map((s) => ({
                                            value: String(s.id),
                                            label: s.nombre,
                                        })),
                                    ]}
                                    error={errors.sub_marca_id}
                                />
                                <Select
                                    label="Unidad de medida"
                                    name="unidad_medida_id"
                                    value={form.unidad_medida_id}
                                    onChange={setField('unidad_medida_id')}
                                    options={[
                                        { value: '', label: 'Seleccione...' },
                                        ...unidadOptions,
                                    ]}
                                    error={errors.unidad_medida_id}
                                />
                            </div>
                        </section>

                        <section>
                            <h3 className="mb-2 text-xs font-semibold uppercase tracking-wider text-gray-500">
                                Unidades y conversión
                            </h3>
                            <div className="grid gap-4 sm:grid-cols-2">
                                <Select
                                    label="Unidad de compra (opcional)"
                                    name="unidad_compra_id"
                                    value={form.unidad_compra_id}
                                    onChange={setField('unidad_compra_id')}
                                    options={[{ value: '', label: 'Sin unidad' }, ...unidadOptions]}
                                    error={errors.unidad_compra_id}
                                />
                                <Select
                                    label="Unidad base (inventario)"
                                    name="unidad_base_id"
                                    value={form.unidad_base_id}
                                    onChange={setField('unidad_base_id')}
                                    options={[{ value: '', label: 'Sin unidad' }, ...unidadOptions]}
                                    error={errors.unidad_base_id}
                                />
                                <Input
                                    label="1 unidad compra = ? unidad base"
                                    name="factor_compra_base"
                                    type="number"
                                    step="any"
                                    min="0.01"
                                    value={form.factor_compra_base}
                                    onChange={setField('factor_compra_base')}
                                    error={errors.factor_compra_base}
                                />
                            </div>
                        </section>
                    </div>
                ) : (
                    <div className="space-y-6">
                        <section>
                            <div className="mb-2 flex items-center justify-between">
                                <h3 className="text-xs font-semibold uppercase tracking-wider text-gray-500">
                                    Presentaciones
                                </h3>
                                <Button variant="secondary" size="sm" onClick={addPresentacion}>
                                    <Plus className="h-4 w-4" />
                                    Agregar
                                </Button>
                            </div>
                            {presentaciones.length === 0 && (
                                <p className="rounded-lg border border-dashed border-gray-300 p-6 text-center text-sm text-gray-400">
                                    Agregue al menos una presentación (ej: 500g, 1kg, 3L)
                                </p>
                            )}
                            <div className="space-y-3">
                                {presentaciones.map((p, index) => (
                                    <div
                                        key={index}
                                        className="rounded-lg border border-edge bg-gray-50 p-4"
                                    >
                                        <div className="mb-3 flex items-center justify-between">
                                            <p className="text-sm font-semibold text-warm-900">
                                                Presentación {index + 1}
                                            </p>
                                            <button
                                                type="button"
                                                aria-label="Quitar presentación"
                                                onClick={() => removePresentacion(index)}
                                                className="rounded-md p-1 text-red-600 transition hover:bg-red-50"
                                            >
                                                <X className="h-4 w-4" />
                                            </button>
                                        </div>
                                        <div className="grid gap-3 sm:grid-cols-2">
                                            <Input
                                                label="Nombre (ej: 500g, 1kg)"
                                                value={p.nombre}
                                                onChange={setPresentacionField(index, 'nombre')}
                                                error={errors[`presentaciones.${index}.nombre`]}
                                            />
                                            <Input
                                                label="Código de barras"
                                                value={p.codigo_barras}
                                                onChange={setPresentacionField(index, 'codigo_barras')}
                                                error={errors[`presentaciones.${index}.codigo_barras`]}
                                            />
                                            <Input
                                                label="Precio venta (S/)"
                                                type="number"
                                                step="any"
                                                min="0"
                                                value={p.precio_venta}
                                                onChange={setPresentacionField(index, 'precio_venta')}
                                                error={errors[`presentaciones.${index}.precio_venta`]}
                                            />
                                            <div className="grid grid-cols-2 gap-3">
                                                <Input
                                                    label="Factor (a unidad base)"
                                                    type="number"
                                                    step="any"
                                                    min="0.01"
                                                    value={p.factor_conversion}
                                                    onChange={setPresentacionField(index, 'factor_conversion')}
                                                    error={
                                                        errors[
                                                            `presentaciones.${index}.factor_conversion`
                                                        ]
                                                    }
                                                />
                                                <Select
                                                    label="Unidad base"
                                                    value={p.unidad_base_id}
                                                    onChange={setPresentacionField(
                                                        index,
                                                        'unidad_base_id',
                                                    )}
                                                    options={[
                                                        { value: '', label: '—' },
                                                        ...unidadOptions,
                                                    ]}
                                                />
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </section>

                        <section>
                            <h3 className="mb-2 text-xs font-semibold uppercase tracking-wider text-gray-500">
                                Precio y detalle
                            </h3>
                            <div className="grid gap-4 sm:grid-cols-2">
                                <Input
                                    label="Precio base (S/)"
                                    name="precio_base"
                                    type="number"
                                    step="any"
                                    min="0"
                                    value={form.precio_base}
                                    onChange={setField('precio_base')}
                                    error={errors.precio_base}
                                />
                                <Input
                                    label="Descripción"
                                    name="descripcion"
                                    value={form.descripcion}
                                    onChange={setField('descripcion')}
                                    error={errors.descripcion}
                                />
                            </div>
                            <div className="mt-4 flex flex-wrap gap-6">
                                <label className="flex items-center gap-2 text-sm text-gray-700">
                                    <input
                                        type="checkbox"
                                        checked={form.afecto_igv}
                                        onChange={setField('afecto_igv')}
                                        className="h-4 w-4 rounded border-gray-300 accent-primary-600"
                                    />
                                    Afecto a IGV
                                </label>
                                <label className="flex items-center gap-2 text-sm text-gray-700">
                                    <input
                                        type="checkbox"
                                        checked={form.activo}
                                        onChange={setField('activo')}
                                        className="h-4 w-4 rounded border-gray-300 accent-primary-600"
                                    />
                                    Producto activo
                                </label>
                            </div>
                        </section>
                    </div>
                )}
            </Modal>

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
                <Alert variant="warning">
                    Se eliminarán también sus presentaciones.
                </Alert>
            </Modal>
        </Layout>
    );
}
