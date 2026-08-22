import { useCallback, useEffect, useMemo, useState } from 'react';
import { Download, TrendingUp } from 'lucide-react';
import {
    Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis,
} from 'recharts';
import api from '../lib/api';
import Layout from '../components/Layout';
import PageHeader from '../components/PageHeader';
import { Alert, Button, Card, Input, Select, Spinner } from '../components/ui';

const money = (n) =>
    new Intl.NumberFormat('es-PE', { style: 'currency', currency: 'PEN' }).format(Number(n) || 0);

const iso = (d) => d.toISOString().slice(0, 10);
const hoy = new Date();
const hace11Meses = new Date(hoy.getFullYear(), hoy.getMonth() - 11, 1);

const MES = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
const etiquetaGrupo = (g, agrupar) => {
    if (agrupar !== 'mes') return g;
    const [y, m] = String(g).split('-');
    return `${MES[Number(m) - 1] ?? m} ${String(y).slice(2)}`;
};

function TotalCard({ label, value, accent = 'text-warm-900' }) {
    return (
        <Card>
            <p className="text-xs font-medium uppercase tracking-wide text-warm-500">{label}</p>
            <p className={`mt-1 text-xl font-extrabold ${accent}`}>{value}</p>
        </Card>
    );
}

export default function Utilidades() {
    const [desde, setDesde] = useState(iso(hace11Meses));
    const [hasta, setHasta] = useState(iso(hoy));
    const [agrupar, setAgrupar] = useState('mes');
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const load = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const res = await api.get(`/reportes/utilidades?desde=${desde}&hasta=${hasta}&agrupar=${agrupar}`);
            setData(res.data);
        } catch {
            setError('No se pudo cargar el reporte de utilidades.');
        } finally {
            setLoading(false);
        }
    }, [desde, hasta, agrupar]);

    useEffect(() => {
        load();
    }, [load]);

    const filas = data?.filas ?? [];
    const tot = data?.totales ?? {};

    const chartData = useMemo(
        () => filas.slice(0, 12).map((f) => ({ ...f, label: etiquetaGrupo(f.grupo, agrupar) })),
        [filas, agrupar],
    );

    const exportCsv = () => {
        const headers = ['Grupo', 'Ventas', 'Costo', 'Ganancia', '% Ganancia', 'Gastos', 'Utilidad neta', 'Margen %'];
        const rows = filas.map((f) => [
            etiquetaGrupo(f.grupo, agrupar), f.ventas, f.costo, f.ganancia, f.margen_ganancia, f.gastos, f.utilidad_neta, f.margen,
        ]);
        const csv = [headers, ...rows].map((r) => r.join(';')).join('\n');
        const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `utilidades_${agrupar}_${desde}_${hasta}.csv`;
        a.click();
        URL.revokeObjectURL(url);
    };

    return (
        <Layout>
            <PageHeader
                title="Utilidades"
                description="Estado de resultados: ventas − costo − gastos (solo soles, sin IGV)"
                actions={
                    <Button variant="secondary" onClick={exportCsv} disabled={!filas.length}>
                        <Download className="h-4 w-4" /> Exportar CSV
                    </Button>
                }
            />

            {/* Filtros */}
            <Card className="mb-6">
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-4">
                    <Input label="Desde" type="date" value={desde} onChange={(e) => setDesde(e.target.value)} />
                    <Input label="Hasta" type="date" value={hasta} onChange={(e) => setHasta(e.target.value)} />
                    <Select
                        label="Agrupar por"
                        value={agrupar}
                        onChange={(e) => setAgrupar(e.target.value)}
                        options={[
                            { value: 'mes', label: 'Mes' },
                            { value: 'producto', label: 'Producto' },
                            { value: 'categoria', label: 'Categoría' },
                        ]}
                    />
                    <div className="flex items-end">
                        <Button onClick={load} className="w-full justify-center">Aplicar</Button>
                    </div>
                </div>
            </Card>

            {error && <Alert variant="error" className="mb-4">{error}</Alert>}

            {loading ? (
                <div className="flex items-center justify-center py-24">
                    <Spinner size="lg" className="text-primary-600" />
                </div>
            ) : (
                <>
                    {/* Totales. Ganancia = Ventas − Costo; Utilidad = Ganancia − Gastos. */}
                    <div className="mb-6 grid grid-cols-2 gap-3 lg:grid-cols-6">
                        <TotalCard label="Ventas" value={money(tot.ventas)} />
                        <TotalCard label="Costo" value={money(tot.costo)} accent="text-amber-600" />
                        <TotalCard label="Ganancia" value={money(tot.ganancia)} accent="text-blue-600" />
                        <TotalCard label="% Ganancia" value={`${tot.margen_ganancia ?? 0}%`} accent="text-blue-600" />
                        <TotalCard label="Gastos" value={money(tot.gastos)} accent="text-red-600" />
                        <TotalCard label="Utilidad neta" value={money(tot.utilidad_neta)} accent="text-green-600" />
                    </div>

                    {/* Gráfico */}
                    <Card className="mb-6">
                        <h2 className="mb-3 inline-flex items-center gap-2 text-sm font-bold text-warm-900">
                            <TrendingUp className="h-4 w-4 text-primary-600" />
                            {agrupar === 'mes' ? 'Utilidad por mes' : agrupar === 'producto' ? 'Top productos por utilidad' : 'Utilidad por categoría'}
                        </h2>
                        <div className="h-80">
                            {chartData.length ? (
                                <ResponsiveContainer width="100%" height="100%">
                                    <BarChart data={chartData} margin={{ top: 5, right: 10, left: 0, bottom: 0 }}>
                                        <CartesianGrid strokeDasharray="3 3" stroke="#f0ece6" vertical={false} />
                                        <XAxis dataKey="label" tick={{ fontSize: 11 }} stroke="#a9866a" interval={0} angle={agrupar === 'mes' ? 0 : -20} textAnchor={agrupar === 'mes' ? 'middle' : 'end'} height={agrupar === 'mes' ? 30 : 60} />
                                        <YAxis tick={{ fontSize: 11 }} stroke="#a9866a" width={54} />
                                        <Tooltip contentStyle={{ borderRadius: 12, border: '1px solid #e0dad2', fontSize: 12 }} formatter={(v) => money(v)} />
                                        <Legend wrapperStyle={{ fontSize: 12 }} />
                                        <Bar dataKey="ventas" name="Ventas" fill="#ef6c00" radius={[4, 4, 0, 0]} />
                                        <Bar dataKey="costo" name="Costo" fill="#f0b27a" radius={[4, 4, 0, 0]} />
                                        <Bar dataKey="utilidad_neta" name="Utilidad neta" fill="#16a34a" radius={[4, 4, 0, 0]} />
                                    </BarChart>
                                </ResponsiveContainer>
                            ) : (
                                <div className="flex h-full items-center justify-center text-sm text-warm-400">Sin datos en el rango.</div>
                            )}
                        </div>
                    </Card>

                    {/* Tabla */}
                    <Card>
                        <div className="overflow-x-auto">
                            <table className="w-full min-w-[720px] text-sm">
                                <thead>
                                    <tr className="bg-primary-600 text-left text-xs font-semibold uppercase tracking-wide text-white">
                                        <th className="px-3 py-2.5">{agrupar === 'mes' ? 'Mes' : agrupar === 'producto' ? 'Producto' : 'Categoría'}</th>
                                        <th className="px-3 py-2.5 text-right">Ventas</th>
                                        <th className="px-3 py-2.5 text-right">Costo</th>
                                        <th className="px-3 py-2.5 text-right">Ganancia</th>
                                        <th className="px-3 py-2.5 text-right">% Gan.</th>
                                        {agrupar === 'mes' && <th className="px-3 py-2.5 text-right">Gastos</th>}
                                        <th className="px-3 py-2.5 text-right">Utilidad</th>
                                        <th className="px-3 py-2.5 text-right">Margen</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-100">
                                    {filas.length === 0 && (
                                        <tr><td colSpan={8} className="px-3 py-10 text-center text-warm-400">Sin datos en el rango.</td></tr>
                                    )}
                                    {filas.map((f) => (
                                        <tr key={f.grupo} className="hover:bg-gray-50">
                                            <td className="px-3 py-2 font-medium text-warm-900">{etiquetaGrupo(f.grupo, agrupar)}</td>
                                            <td className="px-3 py-2 text-right">{money(f.ventas)}</td>
                                            <td className="px-3 py-2 text-right text-amber-600">{money(f.costo)}</td>
                                            <td className="px-3 py-2 text-right text-blue-600">{money(f.ganancia)}</td>
                                            <td className="px-3 py-2 text-right text-blue-600">{f.margen_ganancia}%</td>
                                            {agrupar === 'mes' && <td className="px-3 py-2 text-right text-red-600">{money(f.gastos)}</td>}
                                            <td className="px-3 py-2 text-right font-semibold text-green-600">{money(f.utilidad_neta)}</td>
                                            <td className="px-3 py-2 text-right">{f.margen}%</td>
                                        </tr>
                                    ))}
                                </tbody>
                                {filas.length > 0 && (
                                    <tfoot>
                                        <tr className="border-t-2 border-edge bg-gray-50 font-bold text-warm-900">
                                            <td className="px-3 py-2.5">Total</td>
                                            <td className="px-3 py-2.5 text-right">{money(tot.ventas)}</td>
                                            <td className="px-3 py-2.5 text-right">{money(tot.costo)}</td>
                                            <td className="px-3 py-2.5 text-right">{money(tot.ganancia)}</td>
                                            <td className="px-3 py-2.5 text-right">{tot.margen_ganancia}%</td>
                                            {agrupar === 'mes' && <td className="px-3 py-2.5 text-right">{money(tot.gastos)}</td>}
                                            <td className="px-3 py-2.5 text-right text-green-700">{money(tot.utilidad_neta)}</td>
                                            <td className="px-3 py-2.5 text-right">{tot.margen}%</td>
                                        </tr>
                                    </tfoot>
                                )}
                            </table>
                        </div>
                        {agrupar !== 'mes' && (
                            <p className="mt-3 text-xs text-warm-400">
                                Los gastos operativos solo se reparten por mes; al agrupar por producto/categoría se muestra la utilidad bruta (ventas − costo).
                            </p>
                        )}
                    </Card>
                </>
            )}
        </Layout>
    );
}
