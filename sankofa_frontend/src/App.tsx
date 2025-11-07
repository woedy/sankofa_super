import { Navigate, Route, Routes } from 'react-router-dom';
import Landing from './routes/Landing';
import Onboarding from './routes/onboarding/Onboarding';
import Login from './routes/auth/Login';
import KycFlow from './routes/auth/KycFlow';
import AppLayout from './routes/app/AppLayout';
import Home from './routes/app/Home';
import Groups from './routes/app/Groups';
import CreateGroup from './routes/app/CreateGroup';
import GroupDetail from './routes/app/GroupDetail';
import Savings from './routes/app/Savings';
import SavingsDetail from './routes/app/SavingsDetail';
import Transactions from './routes/app/Transactions';
import Notifications from './routes/app/Notifications';
import Profile from './routes/app/Profile';
import Support from './routes/app/Support';
import ProtectedRoute from './components/ProtectedRoute';

const App = () => {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route path="/onboarding" element={<Onboarding />} />
      <Route path="/auth/login" element={<Login />} />
      <Route path="/auth/kyc" element={<KycFlow />} />
      <Route path="/app" element={<ProtectedRoute><AppLayout /></ProtectedRoute>}>
        <Route index element={<Navigate to="home" replace />} />
        <Route path="home" element={<Home />} />
        <Route path="groups" element={<Groups />} />
        <Route path="groups/create" element={<CreateGroup />} />
        <Route path="groups/:id" element={<GroupDetail />} />
        <Route path="savings" element={<Savings />} />
        <Route path="savings/:id" element={<SavingsDetail />} />
        <Route path="transactions" element={<Transactions />} />
        <Route path="notifications" element={<Notifications />} />
        <Route path="profile" element={<Profile />} />
        <Route path="support" element={<Support />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

export default App;
