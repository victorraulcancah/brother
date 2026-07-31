import Sidebar from './Sidebar';

export default function Layout({ children }) {
    return (
        <div className="min-h-screen bg-cream">
            <Sidebar />
            <div className="flex min-h-screen flex-col lg:pl-64">
                <main className="flex-1 px-4 pb-6 pt-16 sm:px-6 lg:px-8 lg:pt-6">{children}</main>
            </div>
        </div>
    );
}
