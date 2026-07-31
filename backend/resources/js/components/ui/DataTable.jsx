import { useEffect, useMemo, useRef, useState } from 'react';
import { Eye, Search, SlidersHorizontal, X } from 'lucide-react';
import useDebounce from '../../hooks/useDebounce';
import { cn } from './cn';
import Spinner from './Spinner';

function ToolbarButton({ label, children, onClick }) {
    return (
        <button
            type="button"
            onClick={onClick}
            aria-label={label}
            title={label}
            className="relative inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-md text-gray-500 transition hover:bg-gray-100 hover:text-gray-900"
        >
            {children}
        </button>
    );
}

function Dropdown({ open, onClose, children, align = 'right' }) {
    const ref = useRef(null);

    useEffect(() => {
        const handler = (e) => {
            if (ref.current && !ref.current.contains(e.target)) {
                onClose();
            }
        };
        document.addEventListener('mousedown', handler);
        return () => document.removeEventListener('mousedown', handler);
    }, [onClose]);

    if (!open) return null;

    return (
        <div
            ref={ref}
            className={cn(
                'absolute z-30 mt-1 w-64 rounded-lg border border-edge bg-white p-2 shadow-lg',
                align === 'right' ? 'right-0' : 'left-0',
            )}
        >
            {children}
        </div>
    );
}

export default function DataTable({
    columns,
    rows = [],
    keyField = 'id',
    searchable = true,
    searchPlaceholder = 'Buscar...',
    filterable = false,
    filters = null,
    filterCount = 0,
    toggleableColumns = true,
    loading = false,
    emptyMessage = 'No hay registros para mostrar',
    onRowClick = null,
}) {
    const [search, setSearch] = useState('');
    const debouncedSearch = useDebounce(search, 300);
    const [hiddenColumns, setHiddenColumns] = useState({});
    const [filterOpen, setFilterOpen] = useState(false);
    const [columnsOpen, setColumnsOpen] = useState(false);

    const visibleColumns = useMemo(
        () => columns.filter((col) => !hiddenColumns[col.key]),
        [columns, hiddenColumns],
    );

    const filteredRows = useMemo(() => {
        if (!debouncedSearch.trim()) return rows;
        const q = debouncedSearch.trim().toLowerCase();
        return rows.filter((row) =>
            visibleColumns.some((col) => {
                if (col.searchable === false) return false;
                const value = col.getSearchValue
                    ? col.getSearchValue(row)
                    : row[col.key];
                return value != null && String(value).toLowerCase().includes(q);
            }),
        );
    }, [rows, debouncedSearch, visibleColumns]);

    const toggleColumn = (key) => {
        setHiddenColumns((prev) => {
            const next = { ...prev };
            if (next[key]) {
                delete next[key];
            } else {
                next[key] = true;
            }
            return next;
        });
    };

    const resetColumns = () => setHiddenColumns({});

    const isActionsColumn = (col) => col.type === 'actions';

    return (
        <div className="rounded-lg border border-edge bg-white shadow-sm">
            {(searchable || filterable || toggleableColumns) && (
                <>
                    <div className="flex flex-wrap items-center gap-2 border-b border-edge px-3 py-2.5 sm:px-4">
                        <div className="flex items-center gap-2">
                            {filterable && (
                                <ToolbarButton
                                    label="Filtros"
                                    onClick={() => {
                                        setFilterOpen((v) => !v);
                                        setColumnsOpen(false);
                                    }}
                                >
                                    <SlidersHorizontal className="h-4 w-4" />
                                    {filterCount > 0 && (
                                        <span className="absolute -right-1 -top-1 flex h-4 w-4 items-center justify-center rounded-full bg-primary-600 text-[10px] font-bold text-white">
                                            {filterCount}
                                        </span>
                                    )}
                                </ToolbarButton>
                            )}

                            {toggleableColumns && (
                                <div className="relative">
                                    <ToolbarButton
                                        label="Mostrar / ocultar columnas"
                                        onClick={() => {
                                            setColumnsOpen((v) => !v);
                                            setFilterOpen(false);
                                        }}
                                    >
                                        <Eye className="h-4 w-4" />
                                    </ToolbarButton>
                                    <Dropdown
                                        open={columnsOpen}
                                        onClose={() => setColumnsOpen(false)}
                                    >
                                        <div className="flex items-center justify-between px-2 pb-1 pt-0.5">
                                            <p className="text-xs font-semibold uppercase tracking-wider text-gray-500">
                                                Columnas
                                            </p>
                                            {Object.keys(hiddenColumns).length > 0 && (
                                                <button
                                                    type="button"
                                                    onClick={resetColumns}
                                                    className="text-xs font-medium text-red-600 hover:text-red-700"
                                                >
                                                    Restablecer
                                                </button>
                                            )}
                                        </div>
                                        {columns
                                            .filter((col) => col.type !== 'actions')
                                            .map((col) => (
                                                <label
                                                    key={col.key}
                                                    className="flex cursor-pointer select-none items-center gap-2 rounded-md px-2 py-1.5 text-sm text-gray-700 hover:bg-gray-50"
                                                >
                                                    <input
                                                        type="checkbox"
                                                        checked={!hiddenColumns[col.key]}
                                                        onChange={() => toggleColumn(col.key)}
                                                        className="h-4 w-4 rounded border-gray-300 accent-primary-600"
                                                    />
                                                    {col.label}
                                                </label>
                                            ))}
                                    </Dropdown>
                                </div>
                            )}
                        </div>

                        {searchable && (
                            <div className="relative ml-auto w-full sm:w-64">
                                <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                                <input
                                    type="search"
                                    value={search}
                                    onChange={(e) => setSearch(e.target.value)}
                                    placeholder={searchPlaceholder}
                                    className="block w-full rounded-md border-0 bg-gray-50 py-2 pl-9 pr-9 text-sm text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:bg-white focus:ring-2 focus:ring-inset focus:ring-primary-600"
                                />
                                {search && (
                                    <button
                                        type="button"
                                        onClick={() => setSearch('')}
                                        aria-label="Limpiar búsqueda"
                                        className="absolute right-2 top-1/2 -translate-y-1/2 rounded p-0.5 text-gray-400 hover:text-gray-600"
                                    >
                                        <X className="h-4 w-4" />
                                    </button>
                                )}
                            </div>
                        )}
                    </div>

                    {filterable && filterOpen && (
                        <div className="border-b border-edge bg-gray-50 px-4 py-3">
                            {filters}
                        </div>
                    )}
                </>
            )}

            <div className="overflow-x-auto">
                {loading ? (
                    <div className="flex items-center justify-center py-16">
                        <Spinner size="lg" className="text-primary-600" />
                    </div>
                ) : (
                    <>
                        <div className="hidden md:block">
                            <table className="w-full text-left text-sm">
                            <thead>
                                <tr className="bg-primary-600 text-white">
                                    {visibleColumns.map((col) => (
                                        <th
                                            key={col.key}
                                            scope="col"
                                            className={cn(
                                                'px-4 py-3 text-xs font-semibold uppercase tracking-wide',
                                                col.align === 'right' && 'text-right',
                                                col.headerClassName,
                                            )}
                                        >
                                            {col.label}
                                        </th>
                                    ))}
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {filteredRows.length === 0 && (
                                    <tr>
                                        <td
                                            colSpan={visibleColumns.length}
                                            className="px-4 py-12 text-center text-sm text-gray-400"
                                        >
                                            {emptyMessage}
                                        </td>
                                    </tr>
                                )}
                                {filteredRows.map((row, index) => (
                                    <tr
                                        key={row[keyField] ?? index}
                                        onClick={
                                            onRowClick
                                                ? () => onRowClick(row)
                                                : undefined
                                        }
                                        className={cn(
                                            'transition',
                                            onRowClick
                                                ? 'cursor-pointer hover:bg-primary-50/50'
                                                : 'hover:bg-gray-50',
                                        )}
                                    >
                                        {visibleColumns.map((col) => (
                                            <td
                                                key={col.key}
                                                className={cn(
                                                    'px-4 py-3 text-gray-700',
                                                    col.align === 'right' && 'text-right',
                                                )}
                                            >
                                                {isActionsColumn(col) ? (
                                                    col.render ? (
                                                        col.render(row)
                                                    ) : (
                                                        <span className="flex items-center justify-end gap-1">
                                                            {col.actions?.(row)}
                                                        </span>
                                                    )
                                                ) : col.render ? (
                                                    col.render(row)
                                                ) : (
                                                    row[col.key]
                                                )}
                                            </td>
                                        ))}
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>

                    <div className="divide-y divide-gray-100 md:hidden">                        {filteredRows.length === 0 && (
                            <p className="px-4 py-12 text-center text-sm text-gray-400">
                                {emptyMessage}
                            </p>
                        )}
                        {filteredRows.map((row, index) => {
                            const titleCol = columns[0];
                            const title = titleCol?.render
                                ? titleCol.render(row)
                                : row[titleCol?.key];
                            const bodyCols = columns.filter((col, i) => {
                                if (i === 0 || hiddenColumns[col.key]) return false;
                                if (col.type === 'actions') return false;
                                return true;
                            });
                            const actionsCol = columns.find(isActionsColumn);

                            return (
                                <div
                                    key={row[keyField] ?? index}
                                    onClick={
                                        onRowClick ? () => onRowClick(row) : undefined
                                    }
                                    className={cn(
                                        'px-4 py-3',
                                        onRowClick && 'cursor-pointer',
                                    )}
                                >
                                    <div className="flex items-start justify-between gap-3">
                                        <div className="min-w-0">
                                            <div className="text-sm font-semibold text-warm-900">
                                                {title}
                                            </div>
                                        </div>
                                        {actionsCol && (
                                            <div
                                                className="flex shrink-0 items-center gap-1"
                                                onClick={(e) => e.stopPropagation()}
                                            >
                                                {actionsCol.actions?.(row)}
                                            </div>
                                        )}
                                    </div>
                                    {bodyCols.length > 0 && (
                                        <dl className="mt-2 space-y-1">
                                            {bodyCols.map((col) => (
                                                <div
                                                    key={col.key}
                                                    className="flex items-center justify-between gap-3 text-sm"
                                                >
                                                    <dt className="shrink-0 text-xs text-gray-500">
                                                        {col.label}
                                                    </dt>
                                                    <dd className="min-w-0 truncate text-right text-gray-800">
                                                        {col.render
                                                            ? col.render(row)
                                                            : row[col.key]}
                                                    </dd>
                                                </div>
                                            ))}
                                        </dl>
                                    )}
                                </div>
                            );
                        })}
                    </div>
                    </>
                )}
            </div>
        </div>
    );
}
